import CloudKit
import XCTest
@testable import PoolStats

final class CloudKitStoreTests: XCTestCase {
    func testUnknownItemDeletionErrorIsIgnorable() {
        let error = CKError(.unknownItem)
        XCTAssertTrue(CloudKitStore.isIgnorableDeletionError(error))
    }

    func testPartialFailureWithOnlyUnknownItemsIsIgnorable() {
        let recordID = CKRecord.ID(recordName: "session-1")
        let nested = CKError(.unknownItem)
        let error = CKError(
            .partialFailure,
            userInfo: [CKPartialErrorsByItemIDKey: [recordID: nested]]
        )

        XCTAssertTrue(CloudKitStore.isIgnorableDeletionError(error))
    }

    func testPartialFailureWithRealErrorIsNotIgnorable() {
        let recordID = CKRecord.ID(recordName: "session-1")
        let nested = CKError(.networkUnavailable)
        let error = CKError(
            .partialFailure,
            userInfo: [CKPartialErrorsByItemIDKey: [recordID: nested]]
        )

        XCTAssertFalse(CloudKitStore.isIgnorableDeletionError(error))
    }
}
