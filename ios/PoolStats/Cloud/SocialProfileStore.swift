import CloudKit
import Foundation
import UIKit

struct PublicPlayerProfile: Codable, Equatable, Identifiable {
    var id: String { friendCode }
    var displayName: String
    var friendCode: String
    var recordName: String?
    var ownerRecordName: String?
    var updatedAt: Date

    var maskedOwnerRecordName: String {
        guard let ownerRecordName, !ownerRecordName.isEmpty else { return "—" }
        if ownerRecordName.count <= 10 { return ownerRecordName }
        return "\(ownerRecordName.prefix(4))…\(ownerRecordName.suffix(4))"
    }
}

struct SocialFriend: Codable, Equatable, Identifiable {
    var id: String { friendCode }
    var displayName: String
    var friendCode: String
    var recordName: String?
    var ownerRecordName: String?
    var addedAt: Date
    var updatedAt: Date

    var publicProfile: PublicPlayerProfile {
        PublicPlayerProfile(
            displayName: displayName,
            friendCode: friendCode,
            recordName: recordName,
            ownerRecordName: ownerRecordName,
            updatedAt: updatedAt
        )
    }
}

struct OutgoingMatchShare: Codable, Equatable, Identifiable {
    var id: String { inviteUUID }
    var inviteUUID: String
    var recordName: String?
    var senderFriendCode: String
    var senderDisplayName: String
    var recipientFriendCode: String
    var recipientDisplayName: String
    var recipientOwnerRecordName: String?
    var sessionUUID: String
    var sessionJSON: String
    var sessionLabel: String
    var game: String
    var type: String
    var opponent: String
    var wins: Int
    var losses: Int
    var createdAt: Date
    var status: String
    var failureMessage: String?
    var acceptedAt: Date? = nil

    var scoreText: String { "\(wins):\(losses)" }
    var isPending: Bool { status == "pending" }
    var isAccepted: Bool { status == "accepted" }
    var isDeclined: Bool { status == "declined" }
    var isFailed: Bool { status == "failed" }
}

struct IncomingMatchShare: Codable, Equatable, Identifiable {
    var id: String { inviteUUID }
    var inviteUUID: String
    var recordName: String?
    var senderFriendCode: String
    var senderDisplayName: String
    var recipientFriendCode: String
    var sessionUUID: String
    var sessionJSON: String
    var sessionLabel: String
    var game: String
    var type: String
    var opponent: String
    var wins: Int
    var losses: Int
    var createdAt: Date
    var acceptedAt: Date?
    var status: String
    var failureMessage: String?

    var scoreText: String { "\(wins):\(losses)" }
    var isPending: Bool { status == "pending" }
    var isAccepted: Bool { status == "accepted" }
    var isDeclined: Bool { status == "declined" }
}

@MainActor
final class SocialProfileStore: ObservableObject {
    enum PublishState: Equatable {
        case idle
        case loading
        case saving
        case synced(Date)
        case localOnly(String)
        case failed(String)
    }

    enum FriendLookupState: Equatable {
        case idle
        case searching
        case found(PublicPlayerProfile)
        case added(SocialFriend)
        case failed(String)
    }

    enum MatchShareState: Equatable {
        case idle
        case sending(String)
        case sent(OutgoingMatchShare)
        case failed(String)
    }

    enum IncomingShareState: Equatable {
        case idle
        case loading
        case accepting(String)
        case declining(String)
        case accepted(IncomingMatchShare)
        case declined(IncomingMatchShare)
        case failed(String)
    }

    enum OutgoingShareRefreshState: Equatable {
        case idle
        case loading(String?)
        case synced(Date)
        case failed(String)
    }

    @Published private(set) var profile: PublicPlayerProfile?
    @Published private(set) var publishState: PublishState = .idle
    @Published private(set) var friends: [SocialFriend] = []
    @Published private(set) var friendLookupState: FriendLookupState = .idle
    @Published private(set) var outgoingShares: [OutgoingMatchShare] = []
    @Published private(set) var incomingShares: [IncomingMatchShare] = []
    @Published private(set) var matchShareState: MatchShareState = .idle
    @Published private(set) var incomingShareState: IncomingShareState = .idle
    @Published private(set) var outgoingShareRefreshState: OutgoingShareRefreshState = .idle
    @Published var displayName: String = ""
    @Published var friendCodeQuery: String = ""
    @Published var lastError: String?

    private enum Constants {
        static let recordType = "PublicPlayerProfile"
        static let matchShareRecordType = "FriendMatchShare"
        static let displayName = "displayName"
        static let friendCode = "friendCode"
        static let ownerRecordName = "ownerRecordName"
        static let updatedAt = "updatedAt"
        static let localFilename = "social-profile.json"
        static let friendsFilename = "social-friends.json"
        static let outgoingSharesFilename = "social-outgoing-shares.json"
        static let incomingSharesFilename = "social-incoming-shares.json"

        static let inviteUUID = "inviteUUID"
        static let senderFriendCode = "senderFriendCode"
        static let senderDisplayName = "senderDisplayName"
        static let recipientFriendCode = "recipientFriendCode"
        static let recipientDisplayName = "recipientDisplayName"
        static let recipientOwnerRecordName = "recipientOwnerRecordName"
        static let sessionUUID = "sessionUUID"
        static let sessionJSON = "sessionJSON"
        static let sessionLabel = "sessionLabel"
        static let game = "game"
        static let type = "type"
        static let opponent = "opponent"
        static let wins = "wins"
        static let losses = "losses"
        static let createdAt = "createdAt"
        static let acceptedAt = "acceptedAt"
        static let status = "status"
    }

    private let container: CKContainer
    private let db: CKDatabase
    private let localURL: URL
    private let friendsURL: URL
    private let outgoingSharesURL: URL
    private let incomingSharesURL: URL

    init(container: CKContainer = .default()) {
        self.container = container
        self.db = container.publicCloudDatabase

        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("PoolStats", isDirectory: true)
        localURL = dir.appendingPathComponent(Constants.localFilename)
        friendsURL = dir.appendingPathComponent(Constants.friendsFilename)
        outgoingSharesURL = dir.appendingPathComponent(Constants.outgoingSharesFilename)
        incomingSharesURL = dir.appendingPathComponent(Constants.incomingSharesFilename)

        loadLocal()
        loadFriendsLocal()
        loadOutgoingSharesLocal()
        loadIncomingSharesLocal()
    }

    func refresh() async {
        guard let current = profile, let recordName = current.recordName else { return }
        publishState = .loading
        do {
            let record = try await db.record(for: CKRecord.ID(recordName: recordName))
            let updated = profile(from: record, fallback: current)
            apply(updated)
            publishState = .synced(Date())
            lastError = nil
        } catch {
            publishState = .localOnly("Using the profile saved on this device.")
            lastError = readableMessage(for: error)
        }
    }

    func createOrUpdateProfile(displayName rawDisplayName: String) async {
        let cleaned = rawDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else {
            lastError = "Enter a display name first."
            publishState = .failed("Enter a display name first.")
            return
        }

        publishState = .saving
        lastError = nil

        var draft = profile ?? PublicPlayerProfile(
            displayName: cleaned,
            friendCode: Self.generateFriendCode(),
            recordName: nil,
            ownerRecordName: nil,
            updatedAt: Date()
        )
        draft.displayName = cleaned
        draft.updatedAt = Date()
        if draft.recordName == nil {
            draft.recordName = Self.recordName(for: draft.friendCode)
        }

        // Keep a local profile immediately, even if the public publish fails.
        apply(draft)

        do {
            let saved = try await saveToPublicCloud(draft)
            apply(saved)
            publishState = .synced(Date())
        } catch {
            publishState = .localOnly("Saved locally. Tap publish again when iCloud is available.")
            lastError = readableMessage(for: error)
        }
    }

    func copyFriendCode() {
        guard let code = profile?.friendCode else { return }
        UIPasteboard.general.string = code
    }

    func lookupFriendByCode(_ rawCode: String? = nil) async {
        let normalized = Self.normalizeFriendCode(rawCode ?? friendCodeQuery)
        friendCodeQuery = normalized

        guard Self.isValidFriendCode(normalized) else {
            friendLookupState = .failed("Enter a code like PS-ABC-123.")
            return
        }

        if normalized == profile?.friendCode {
            friendLookupState = .failed("That is your own friend code.")
            return
        }

        if let existing = friends.first(where: { $0.friendCode == normalized }) {
            friendLookupState = .added(existing)
            return
        }

        friendLookupState = .searching
        do {
            let recordName = Self.recordName(for: normalized)
            let record = try await db.record(for: CKRecord.ID(recordName: recordName))
            let fallback = PublicPlayerProfile(
                displayName: "Pool player",
                friendCode: normalized,
                recordName: recordName,
                ownerRecordName: nil,
                updatedAt: Date()
            )
            let found = profile(from: record, fallback: fallback)
            friendLookupState = .found(found)
            lastError = nil
        } catch let error as CKError where error.code == .unknownItem {
            friendLookupState = .failed("No player found for \(normalized).")
        } catch {
            friendLookupState = .failed(readableMessage(for: error))
        }
    }

    @discardableResult
    func addFoundFriend() -> SocialFriend? {
        guard case .found(let found) = friendLookupState else { return nil }
        return addFriend(found)
    }

    @discardableResult
    func addFriend(_ publicProfile: PublicPlayerProfile) -> SocialFriend? {
        let normalized = Self.normalizeFriendCode(publicProfile.friendCode)
        guard Self.isValidFriendCode(normalized) else {
            friendLookupState = .failed("That friend code is not valid.")
            return nil
        }
        guard normalized != profile?.friendCode else {
            friendLookupState = .failed("That is your own friend code.")
            return nil
        }

        let friend = SocialFriend(
            displayName: publicProfile.displayName,
            friendCode: normalized,
            recordName: publicProfile.recordName ?? Self.recordName(for: normalized),
            ownerRecordName: publicProfile.ownerRecordName,
            addedAt: friends.first(where: { $0.friendCode == normalized })?.addedAt ?? Date(),
            updatedAt: publicProfile.updatedAt
        )

        if let idx = friends.firstIndex(where: { $0.friendCode == normalized }) {
            friends[idx] = friend
        } else {
            friends.insert(friend, at: 0)
        }

        sortFriends()
        saveFriendsLocal()
        friendLookupState = .added(friend)
        friendCodeQuery = ""
        return friend
    }

    func removeFriend(friendCode: String) {
        let normalized = Self.normalizeFriendCode(friendCode)
        friends.removeAll { $0.friendCode == normalized }
        saveFriendsLocal()
    }

    func resetFriendLookup() {
        friendLookupState = .idle
        friendCodeQuery = ""
    }

    func resetMatchShareState() {
        matchShareState = .idle
    }

    func resetIncomingShareState() {
        incomingShareState = .idle
    }

    func latestOutgoingShare(for session: Session, friendCode: String) -> OutgoingMatchShare? {
        let normalized = Self.normalizeFriendCode(friendCode)
        return outgoingShares
            .filter { $0.sessionUUID == session.sessionUUID && $0.recipientFriendCode == normalized }
            .sorted { $0.createdAt > $1.createdAt }
            .first
    }

    func refreshOutgoingShares(for sessionUUID: String? = nil) async {
        guard let profile else { return }

        outgoingShareRefreshState = .loading(sessionUUID)
        do {
            let senderPredicate = NSPredicate(format: "%K == %@", Constants.senderFriendCode, profile.friendCode)
            let predicate: NSPredicate
            if let sessionUUID {
                let sessionPredicate = NSPredicate(format: "%K == %@", Constants.sessionUUID, sessionUUID)
                predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [senderPredicate, sessionPredicate])
            } else {
                predicate = senderPredicate
            }

            let query = CKQuery(recordType: Constants.matchShareRecordType, predicate: predicate)
            query.sortDescriptors = [NSSortDescriptor(key: Constants.createdAt, ascending: false)]
            let records = try await fetchAllPublicRecords(query: query)
            for share in records.compactMap(outgoingShare(from:)) {
                upsertOutgoingShare(share)
            }
            outgoingShareRefreshState = .synced(Date())
            lastError = nil
        } catch {
            outgoingShareRefreshState = .failed(readableMessage(for: error))
        }
    }

    func shareMatch(_ session: Session, with friend: SocialFriend) async {
        guard !session.isPractice, !session.isDrillPractice else {
            matchShareState = .failed("Only match sessions can be shared with friends.")
            return
        }
        guard !session.racks.isEmpty else {
            matchShareState = .failed("Log at least one rack before sharing this match.")
            return
        }
        guard let profile else {
            matchShareState = .failed("Create your public profile in Settings > Me first.")
            return
        }

        let normalizedFriendCode = Self.normalizeFriendCode(friend.friendCode)
        if let existing = latestOutgoingShare(for: session, friendCode: normalizedFriendCode), existing.isPending {
            matchShareState = .sent(existing)
            return
        }

        matchShareState = .sending(normalizedFriendCode)

        do {
            var share = try makeOutgoingShare(session: session, friend: friend, sender: profile)
            let recordID = CKRecord.ID(recordName: matchShareRecordName(for: share.inviteUUID))
            let record = CKRecord(recordType: Constants.matchShareRecordType, recordID: recordID)
            record[Constants.inviteUUID] = share.inviteUUID as CKRecordValue
            record[Constants.senderFriendCode] = share.senderFriendCode as CKRecordValue
            record[Constants.senderDisplayName] = share.senderDisplayName as CKRecordValue
            record[Constants.recipientFriendCode] = share.recipientFriendCode as CKRecordValue
            record[Constants.recipientDisplayName] = share.recipientDisplayName as CKRecordValue
            if let recipientOwnerRecordName = share.recipientOwnerRecordName {
                record[Constants.recipientOwnerRecordName] = recipientOwnerRecordName as CKRecordValue
            }
            record[Constants.sessionUUID] = share.sessionUUID as CKRecordValue
            record[Constants.sessionJSON] = share.sessionJSON as CKRecordValue
            record[Constants.sessionLabel] = share.sessionLabel as CKRecordValue
            record[Constants.game] = share.game as CKRecordValue
            record[Constants.type] = share.type as CKRecordValue
            record[Constants.opponent] = share.opponent as CKRecordValue
            record[Constants.wins] = Int64(share.wins) as CKRecordValue
            record[Constants.losses] = Int64(share.losses) as CKRecordValue
            record[Constants.createdAt] = share.createdAt as CKRecordValue
            record[Constants.status] = share.status as CKRecordValue

            let saved = try await db.save(record)
            share.recordName = saved.recordID.recordName
            upsertOutgoingShare(share)
            matchShareState = .sent(share)
            lastError = nil
        } catch {
            do {
                var failed = try makeOutgoingShare(session: session, friend: friend, sender: profile)
                failed.status = "failed"
                failed.failureMessage = readableMessage(for: error)
                upsertOutgoingShare(failed)
                matchShareState = .failed(failed.failureMessage ?? "Could not share this match.")
            } catch {
                matchShareState = .failed(readableMessage(for: error))
            }
        }
    }

    func refreshIncomingShares() async {
        guard let profile else { return }

        incomingShareState = .loading
        do {
            let predicate = NSPredicate(format: "%K == %@", Constants.recipientFriendCode, profile.friendCode)
            let query = CKQuery(recordType: Constants.matchShareRecordType, predicate: predicate)
            query.sortDescriptors = [NSSortDescriptor(key: Constants.createdAt, ascending: false)]
            let records = try await fetchAllPublicRecords(query: query)
            let remoteShares = records
                .compactMap(incomingShare(from:))
                .sorted { $0.createdAt > $1.createdAt }
            incomingShares = mergedIncomingShares(remoteShares)
            saveIncomingSharesLocal()
            incomingShareState = .idle
            lastError = nil
        } catch {
            incomingShareState = .failed(readableMessage(for: error))
        }
    }

    func acceptIncomingShare(_ share: IncomingMatchShare, savingTo store: DataStore) async {
        guard share.isPending else { return }
        incomingShareState = .accepting(share.inviteUUID)

        do {
            let session = try acceptedSession(from: share)
            await store.saveSession(session)

            var accepted = share
            accepted.status = "accepted"
            accepted.acceptedAt = Date()
            accepted.failureMessage = nil

            try await updateIncomingShareRecord(accepted)
            upsertIncomingShare(accepted)
            incomingShareState = .accepted(accepted)
            lastError = nil
        } catch {
            var failed = share
            failed.failureMessage = readableMessage(for: error)
            upsertIncomingShare(failed)
            incomingShareState = .failed(failed.failureMessage ?? "Could not accept this shared match.")
        }
    }

    func declineIncomingShare(_ share: IncomingMatchShare) async {
        guard share.isPending else { return }
        incomingShareState = .declining(share.inviteUUID)

        do {
            var declined = share
            declined.status = "declined"
            declined.failureMessage = nil
            try await updateIncomingShareRecord(declined)
            upsertIncomingShare(declined)
            incomingShares.removeAll { $0.inviteUUID == declined.inviteUUID }
            saveIncomingSharesLocal()
            incomingShareState = .declined(declined)
            lastError = nil
        } catch {
            incomingShareState = .failed(readableMessage(for: error))
        }
    }

    func refreshFriends() async {
        guard !friends.isEmpty else { return }
        var next = friends

        for friend in friends {
            let recordName = friend.recordName ?? Self.recordName(for: friend.friendCode)
            do {
                let record = try await db.record(for: CKRecord.ID(recordName: recordName))
                let profile = profile(from: record, fallback: friend.publicProfile)
                if let idx = next.firstIndex(where: { $0.friendCode == friend.friendCode }) {
                    next[idx].displayName = profile.displayName
                    next[idx].recordName = profile.recordName
                    next[idx].ownerRecordName = profile.ownerRecordName
                    next[idx].updatedAt = profile.updatedAt
                }
            } catch {
                continue
            }
        }

        friends = next
        sortFriends()
        saveFriendsLocal()
    }

    var statusText: String {
        switch publishState {
        case .idle:
            return profile == nil ? "No public profile yet" : "Profile saved locally"
        case .loading:
            return "Checking public profile…"
        case .saving:
            return "Publishing friend code…"
        case .synced(let date):
            return "Published \(AppFormatters.shortDate(date))"
        case .localOnly(let message):
            return message
        case .failed(let message):
            return message
        }
    }

    var canPublish: Bool {
        !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && publishState != .saving
    }

    private func saveToPublicCloud(_ draft: PublicPlayerProfile) async throws -> PublicPlayerProfile {
        let ownerRecordName = try await currentOwnerRecordName()
        var candidate = draft
        candidate.ownerRecordName = ownerRecordName

        for _ in 0..<6 {
            let recordName = candidate.recordName ?? Self.recordName(for: candidate.friendCode)
            candidate.recordName = recordName
            let recordID = CKRecord.ID(recordName: recordName)
            let existing = try await fetchRecordIfExists(recordID)

            if let existing, isCollision(existing: existing, currentOwnerRecordName: ownerRecordName, localProfile: draft) {
                candidate.friendCode = Self.generateFriendCode()
                candidate.recordName = Self.recordName(for: candidate.friendCode)
                continue
            }

            let record = existing ?? CKRecord(recordType: Constants.recordType, recordID: recordID)
            record[Constants.displayName] = candidate.displayName as CKRecordValue
            record[Constants.friendCode] = candidate.friendCode as CKRecordValue
            record[Constants.ownerRecordName] = ownerRecordName as CKRecordValue
            record[Constants.updatedAt] = candidate.updatedAt as CKRecordValue

            let saved = try await db.save(record)
            return profile(from: saved, fallback: candidate)
        }

        throw SocialProfileError.couldNotAllocateFriendCode
    }

    private func currentOwnerRecordName() async throws -> String {
        let id = try await container.userRecordID()
        return id.recordName
    }

    private func fetchRecordIfExists(_ recordID: CKRecord.ID) async throws -> CKRecord? {
        do {
            return try await db.record(for: recordID)
        } catch let error as CKError where error.code == .unknownItem {
            return nil
        }
    }

    private func isCollision(existing: CKRecord, currentOwnerRecordName: String, localProfile: PublicPlayerProfile) -> Bool {
        let existingOwner = existing[Constants.ownerRecordName] as? String
        if existingOwner == currentOwnerRecordName { return false }

        // If this device already had the record name saved, assume it is an update path
        // unless CloudKit clearly says the record belongs to another owner.
        if localProfile.recordName == existing.recordID.recordName && existingOwner == nil { return false }
        if localProfile.recordName == existing.recordID.recordName && localProfile.ownerRecordName == currentOwnerRecordName { return false }

        return true
    }

    private func profile(from record: CKRecord, fallback: PublicPlayerProfile) -> PublicPlayerProfile {
        PublicPlayerProfile(
            displayName: record[Constants.displayName] as? String ?? fallback.displayName,
            friendCode: record[Constants.friendCode] as? String ?? fallback.friendCode,
            recordName: record.recordID.recordName,
            ownerRecordName: record[Constants.ownerRecordName] as? String ?? fallback.ownerRecordName,
            updatedAt: record[Constants.updatedAt] as? Date ?? fallback.updatedAt
        )
    }

    private func apply(_ next: PublicPlayerProfile) {
        profile = next
        displayName = next.displayName
        saveLocal()
    }

    private func loadLocal() {
        guard let data = try? Data(contentsOf: localURL),
              let decoded = try? JSONDecoder().decode(PublicPlayerProfile.self, from: data) else { return }
        profile = decoded
        displayName = decoded.displayName
    }

    private func saveLocal() {
        guard let profile else { return }
        do {
            try FileManager.default.createDirectory(at: localURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(profile)
            try data.write(to: localURL, options: [.atomic])
        } catch {
            lastError = "Could not save public profile locally."
        }
    }

    private func loadFriendsLocal() {
        guard let data = try? Data(contentsOf: friendsURL),
              let decoded = try? JSONDecoder().decode([SocialFriend].self, from: data) else { return }
        friends = decoded
        sortFriends()
    }

    private func saveFriendsLocal() {
        do {
            try FileManager.default.createDirectory(at: friendsURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(friends)
            try data.write(to: friendsURL, options: [.atomic])
        } catch {
            lastError = "Could not save friends locally."
        }
    }

    private func loadOutgoingSharesLocal() {
        guard let data = try? Data(contentsOf: outgoingSharesURL),
              let decoded = try? JSONDecoder().decode([OutgoingMatchShare].self, from: data) else { return }
        outgoingShares = decoded.sorted { $0.createdAt > $1.createdAt }
    }

    private func saveOutgoingSharesLocal() {
        do {
            try FileManager.default.createDirectory(at: outgoingSharesURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(outgoingShares)
            try data.write(to: outgoingSharesURL, options: [.atomic])
        } catch {
            lastError = "Could not save shared match status locally."
        }
    }

    private func loadIncomingSharesLocal() {
        guard let data = try? Data(contentsOf: incomingSharesURL),
              let decoded = try? JSONDecoder().decode([IncomingMatchShare].self, from: data) else { return }
        incomingShares = decoded
            .filter { !$0.isDeclined }
            .sorted { $0.createdAt > $1.createdAt }
    }

    private func saveIncomingSharesLocal() {
        do {
            try FileManager.default.createDirectory(at: incomingSharesURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(incomingShares)
            try data.write(to: incomingSharesURL, options: [.atomic])
        } catch {
            lastError = "Could not save incoming match invites locally."
        }
    }

    private func upsertOutgoingShare(_ share: OutgoingMatchShare) {
        if let idx = outgoingShares.firstIndex(where: { $0.inviteUUID == share.inviteUUID }) {
            outgoingShares[idx] = share
        } else {
            outgoingShares.removeAll {
                $0.sessionUUID == share.sessionUUID &&
                $0.recipientFriendCode == share.recipientFriendCode &&
                $0.isFailed
            }
            outgoingShares.insert(share, at: 0)
        }
        outgoingShares.sort { $0.createdAt > $1.createdAt }
        saveOutgoingSharesLocal()
    }

    private func upsertIncomingShare(_ share: IncomingMatchShare) {
        if let idx = incomingShares.firstIndex(where: { $0.inviteUUID == share.inviteUUID }) {
            incomingShares[idx] = share
        } else {
            incomingShares.insert(share, at: 0)
        }
        incomingShares.sort { $0.createdAt > $1.createdAt }
        saveIncomingSharesLocal()
    }

    private func mergedIncomingShares(_ remoteShares: [IncomingMatchShare]) -> [IncomingMatchShare] {
        var merged: [String: IncomingMatchShare] = [:]
        for share in remoteShares where !share.isDeclined {
            merged[share.inviteUUID] = share
        }

        for local in incomingShares {
            if local.isDeclined {
                merged.removeValue(forKey: local.inviteUUID)
            } else if local.isAccepted {
                let remoteIsStillPending = merged[local.inviteUUID]?.isPending ?? false
                if remoteIsStillPending || merged[local.inviteUUID] == nil {
                    merged[local.inviteUUID] = local
                }
            }
        }

        return merged.values
            .filter { !$0.isDeclined }
            .sorted { $0.createdAt > $1.createdAt }
    }

    private func sortFriends() {
        friends.sort { lhs, rhs in
            if lhs.addedAt != rhs.addedAt { return lhs.addedAt > rhs.addedAt }
            return lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName) == .orderedAscending
        }
    }

    private func readableMessage(for error: Error) -> String {
        if let ckError = error as? CKError {
            switch ckError.code {
            case .notAuthenticated:
                return "Sign in to iCloud to publish your friend code."
            case .networkUnavailable, .networkFailure:
                return "Network unavailable. Your profile is saved locally."
            case .quotaExceeded:
                return "iCloud storage is full, so the friend code was not published."
            default:
                return ckError.localizedDescription
            }
        }
        return error.localizedDescription
    }

    private static func recordName(for friendCode: String) -> String {
        "PublicPlayerProfile-\(normalizeFriendCode(friendCode).replacingOccurrences(of: " ", with: ""))"
    }

    private func matchShareRecordName(for inviteUUID: String) -> String {
        "FriendMatchShare-\(inviteUUID)"
    }

    private func fetchAllPublicRecords(query: CKQuery) async throws -> [CKRecord] {
        var records: [CKRecord] = []
        var cursor: CKQueryOperation.Cursor?
        repeat {
            let (batch, nextCursor) = try await fetchPublicBatch(query: query, cursor: cursor)
            records.append(contentsOf: batch)
            cursor = nextCursor
        } while cursor != nil
        return records
    }

    private func fetchPublicBatch(query: CKQuery, cursor: CKQueryOperation.Cursor?) async throws -> ([CKRecord], CKQueryOperation.Cursor?) {
        try await withCheckedThrowingContinuation { cont in
            let op: CKQueryOperation = {
                if let cursor { return CKQueryOperation(cursor: cursor) }
                return CKQueryOperation(query: query)
            }()
            var batch: [CKRecord] = []
            op.recordMatchedBlock = { _, result in
                if case .success(let record) = result {
                    batch.append(record)
                }
            }
            op.queryResultBlock = { result in
                switch result {
                case .success(let cursor):
                    cont.resume(returning: (batch, cursor))
                case .failure(let error):
                    cont.resume(throwing: error)
                }
            }
            db.add(op)
        }
    }

    private func updateIncomingShareRecord(_ share: IncomingMatchShare) async throws {
        let recordName = share.recordName ?? matchShareRecordName(for: share.inviteUUID)
        let record = try await db.record(for: CKRecord.ID(recordName: recordName))
        record[Constants.status] = share.status as CKRecordValue
        if let acceptedAt = share.acceptedAt {
            record[Constants.acceptedAt] = acceptedAt as CKRecordValue
        }
        _ = try await db.save(record)
    }

    private func outgoingShare(from record: CKRecord) -> OutgoingMatchShare? {
        guard let inviteUUID = record[Constants.inviteUUID] as? String,
              let senderFriendCode = record[Constants.senderFriendCode] as? String,
              let senderDisplayName = record[Constants.senderDisplayName] as? String,
              let recipientFriendCode = record[Constants.recipientFriendCode] as? String,
              let recipientDisplayName = record[Constants.recipientDisplayName] as? String,
              let sessionUUID = record[Constants.sessionUUID] as? String,
              let sessionJSON = record[Constants.sessionJSON] as? String else {
            return nil
        }

        return OutgoingMatchShare(
            inviteUUID: inviteUUID,
            recordName: record.recordID.recordName,
            senderFriendCode: Self.normalizeFriendCode(senderFriendCode),
            senderDisplayName: senderDisplayName,
            recipientFriendCode: Self.normalizeFriendCode(recipientFriendCode),
            recipientDisplayName: recipientDisplayName,
            recipientOwnerRecordName: record[Constants.recipientOwnerRecordName] as? String,
            sessionUUID: sessionUUID,
            sessionJSON: sessionJSON,
            sessionLabel: record[Constants.sessionLabel] as? String ?? "Shared match",
            game: record[Constants.game] as? String ?? "8ball",
            type: record[Constants.type] as? String ?? "match",
            opponent: record[Constants.opponent] as? String ?? "",
            wins: intValue(record[Constants.wins]),
            losses: intValue(record[Constants.losses]),
            createdAt: record[Constants.createdAt] as? Date ?? Date(),
            status: record[Constants.status] as? String ?? "pending",
            failureMessage: nil,
            acceptedAt: record[Constants.acceptedAt] as? Date
        )
    }

    private func incomingShare(from record: CKRecord) -> IncomingMatchShare? {
        guard let inviteUUID = record[Constants.inviteUUID] as? String,
              let senderFriendCode = record[Constants.senderFriendCode] as? String,
              let senderDisplayName = record[Constants.senderDisplayName] as? String,
              let recipientFriendCode = record[Constants.recipientFriendCode] as? String,
              let sessionUUID = record[Constants.sessionUUID] as? String,
              let sessionJSON = record[Constants.sessionJSON] as? String else {
            return nil
        }

        return IncomingMatchShare(
            inviteUUID: inviteUUID,
            recordName: record.recordID.recordName,
            senderFriendCode: Self.normalizeFriendCode(senderFriendCode),
            senderDisplayName: senderDisplayName,
            recipientFriendCode: Self.normalizeFriendCode(recipientFriendCode),
            sessionUUID: sessionUUID,
            sessionJSON: sessionJSON,
            sessionLabel: record[Constants.sessionLabel] as? String ?? "Shared match",
            game: record[Constants.game] as? String ?? "8ball",
            type: record[Constants.type] as? String ?? "match",
            opponent: record[Constants.opponent] as? String ?? "",
            wins: intValue(record[Constants.wins]),
            losses: intValue(record[Constants.losses]),
            createdAt: record[Constants.createdAt] as? Date ?? Date(),
            acceptedAt: record[Constants.acceptedAt] as? Date,
            status: record[Constants.status] as? String ?? "pending",
            failureMessage: nil
        )
    }

    private func acceptedSession(from share: IncomingMatchShare) throws -> Session {
        guard let data = share.sessionJSON.data(using: .utf8) else {
            throw SocialProfileError.couldNotDecodeMatch
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let original = try decoder.decode(Session.self, from: data)
        return mirroredSession(original, from: share)
    }

    private func mirroredSession(_ original: Session, from share: IncomingMatchShare) -> Session {
        let mirroredRacks = original.racks.map { rack in
            Rack(
                index: rack.index,
                result: mirroredResult(rack.result),
                breaker: mirroredBreaker(rack.breaker),
                breakBalls: rack.breakBalls,
                breakFoul: rack.breakFoul,
                layout: rack.layout,
                outcome: nil,
                fouls: 0,
                badSafety: 0,
                badPosition: 0,
                patternCount: 0,
                missCount: 0,
                runoutFirst: false,
                breakAndRun: false
            )
        }

        return Session(
            id: Self.stableSharedSessionID(for: share.inviteUUID),
            sessionUUID: "shared-\(share.inviteUUID)",
            label: original.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Shared match" : original.label,
            opponent: share.senderDisplayName,
            game: original.game,
            type: original.type,
            ts: original.ts,
            racks: mirroredRacks,
            durationSeconds: original.durationSeconds,
            performanceRating: nil
        )
    }

    private func mirroredResult(_ result: String?) -> String? {
        switch result {
        case "won": return "lost"
        case "lost": return "won"
        default: return result
        }
    }

    private func mirroredBreaker(_ breaker: String) -> String {
        switch breaker {
        case "me": return "opp"
        case "opp": return "me"
        default: return breaker
        }
    }

    private func intValue(_ value: Any?) -> Int {
        if let int = value as? Int { return int }
        if let int64 = value as? Int64 { return Int(int64) }
        if let number = value as? NSNumber { return number.intValue }
        return 0
    }

    private func makeOutgoingShare(session: Session, friend: SocialFriend, sender: PublicPlayerProfile) throws -> OutgoingMatchShare {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(session)
        guard let json = String(data: data, encoding: .utf8) else {
            throw SocialProfileError.couldNotEncodeMatch
        }

        return OutgoingMatchShare(
            inviteUUID: UUID().uuidString,
            recordName: nil,
            senderFriendCode: sender.friendCode,
            senderDisplayName: sender.displayName,
            recipientFriendCode: Self.normalizeFriendCode(friend.friendCode),
            recipientDisplayName: friend.displayName,
            recipientOwnerRecordName: friend.ownerRecordName,
            sessionUUID: session.sessionUUID,
            sessionJSON: json,
            sessionLabel: session.displayLabel,
            game: session.game,
            type: session.type,
            opponent: session.opponent,
            wins: session.wins,
            losses: session.losses,
            createdAt: Date(),
            status: "pending",
            failureMessage: nil
        )
    }

    static func normalizeFriendCode(_ raw: String) -> String {
        let compact = raw.uppercased().filter { $0.isLetter || $0.isNumber }
        let body = compact.hasPrefix("PS") ? String(compact.dropFirst(2)) : compact
        guard body.count >= 6 else {
            return raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        }
        let prefix = body.prefix(3)
        let suffix = body.dropFirst(3).prefix(3)
        return "PS-\(prefix)-\(suffix)"
    }

    static func isValidFriendCode(_ raw: String) -> Bool {
        let normalized = normalizeFriendCode(raw)
        let compact = normalized.uppercased().filter { $0.isLetter || $0.isNumber }
        guard compact.hasPrefix("PS") else { return false }
        return compact.dropFirst(2).count == 6
    }

    private static func generateFriendCode() -> String {
        let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        let first = String((0..<3).map { _ in alphabet.randomElement()! })
        let second = String((0..<3).map { _ in alphabet.randomElement()! })
        return "PS-\(first)-\(second)"
    }

    private static func stableSharedSessionID(for inviteUUID: String) -> Int64 {
        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in inviteUUID.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1_099_511_628_211
        }
        let stable = hash & 0x7FFF_FFFF_FFFF_FFFF
        return Int64(stable == 0 ? 1 : stable)
    }
}

private enum SocialProfileError: LocalizedError {
    case couldNotAllocateFriendCode
    case couldNotEncodeMatch
    case couldNotDecodeMatch

    var errorDescription: String? {
        switch self {
        case .couldNotAllocateFriendCode:
            return "Could not create a unique friend code. Please try again."
        case .couldNotEncodeMatch:
            return "Could not prepare this match for sharing."
        case .couldNotDecodeMatch:
            return "Could not read this shared match."
        }
    }
}
