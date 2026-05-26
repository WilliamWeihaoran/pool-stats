import XCTest

final class ExportCompliancePlistTests: XCTestCase {
    func testMainAppPlistDeclaresOnlyExemptEncryptionUsage() throws {
        let relativePath = "ios/PoolStats/Resources/Info.plist"
        let plist = try readPlist(relativePath: relativePath)
        let value = plist["ITSAppUsesNonExemptEncryption"] as? Bool
        XCTAssertEqual(value, false, "\(relativePath) should declare ITSAppUsesNonExemptEncryption = NO")
    }

    func testWatchBundlePlistsDoNotDeclareEncryptionKey() throws {
        for relativePath in [
            "ios/PoolStats/Watch/WatchApp-Info.plist",
            "ios/PoolStats/Watch/WatchExtension-Info.plist",
            "ios/PoolStats/WatchComplications/Info.plist",
        ] {
            let plist = try readPlist(relativePath: relativePath)
            XCTAssertNil(
                plist["ITSAppUsesNonExemptEncryption"],
                "\(relativePath) should not declare ITSAppUsesNonExemptEncryption"
            )
        }
    }

    private func plistURL(relativePath: String) -> URL? {
        let testFileURL = URL(fileURLWithPath: #filePath)
        let repoRoot = testFileURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        return repoRoot.appendingPathComponent(relativePath)
    }

    private func readPlist(relativePath: String) throws -> [String: Any] {
        let plistURL = try XCTUnwrap(plistURL(relativePath: relativePath))
        return try XCTUnwrap(NSDictionary(contentsOf: plistURL) as? [String: Any], "Could not read \(relativePath)")
    }
}
