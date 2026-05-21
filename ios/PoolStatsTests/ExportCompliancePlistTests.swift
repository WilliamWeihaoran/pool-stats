import XCTest

final class ExportCompliancePlistTests: XCTestCase {
    func testShippedPlistsDeclareOnlyExemptEncryptionUsage() throws {
        for relativePath in [
            "ios/PoolStats/Resources/Info.plist",
            "ios/PoolStats/Watch/WatchApp-Info.plist",
            "ios/PoolStats/Watch/WatchExtension-Info.plist",
            "ios/PoolStats/WatchComplications/Info.plist",
        ] {
            let plistURL = try XCTUnwrap(plistURL(relativePath: relativePath))
            let plist = try XCTUnwrap(NSDictionary(contentsOf: plistURL) as? [String: Any], "Could not read \(relativePath)")
            let value = plist["ITSAppUsesNonExemptEncryption"] as? Bool
            XCTAssertEqual(value, false, "\(relativePath) should declare ITSAppUsesNonExemptEncryption = NO")
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
}
