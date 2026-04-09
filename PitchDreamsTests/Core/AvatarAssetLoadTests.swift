import XCTest
import UIKit
@testable import PitchDreams

final class AvatarAssetLoadTests: XCTestCase {
    /// Verify all 24 avatar imagesets are actually loadable via UIImage(named:).
    /// This guards against asset catalog compilation issues.
    func testAllAvatarAssetsLoadFromBundle() {
        var missing: [String] = []
        for avatar in Avatar.allCases {
            for stage in AvatarStage.allCases {
                let name = avatar.assetName(stage: stage)
                if UIImage(named: name) == nil {
                    missing.append(name)
                }
            }
        }
        XCTAssertTrue(missing.isEmpty, "Missing avatar assets: \(missing)")
    }

    func testLegacyMigrationResolvesToLoadableAsset() {
        let legacyIds = ["defender_girl_01", "midfield_boy_01", "midfield_boy_02", "winger_boy_01"]
        for id in legacyIds {
            let assetName = Avatar.assetName(for: id, milestones: [])
            XCTAssertNotNil(
                UIImage(named: assetName),
                "Legacy id '\(id)' resolved to '\(assetName)' which is not loadable"
            )
        }
    }
}
