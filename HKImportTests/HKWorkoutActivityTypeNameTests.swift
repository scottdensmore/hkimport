import HealthKit
import XCTest
@testable import HKImport

final class HKWorkoutActivityTypeNameTests: XCTestCase {
    func testPrefixedIdentifierMapsToExpectedActivityType() {
        let activity = HKWorkoutActivityType.activityTypeFromString("HKWorkoutActivityTypeRunning")

        XCTAssertEqual(activity, .running)
    }

    func testNormalizedNameMapsToExpectedActivityType() {
        let activity = HKWorkoutActivityType.activityTypeFromString("high intensity interval training")

        XCTAssertEqual(activity, .highIntensityIntervalTraining)
    }

    func testAlternateIdentifierMapsToSocialDance() {
        let activity = HKWorkoutActivityType.activityTypeFromString("HKWorkoutActivityTypeDanceInspiredTraining")

        XCTAssertEqual(activity, .socialDance)
    }

    func testUnknownNameFallsBackToOther() {
        let activity = HKWorkoutActivityType.activityTypeFromString("HKWorkoutActivityTypeNotARealWorkout")

        XCTAssertEqual(activity, .other)
    }

    func testValuesProvidesNameLookupByDisplayName() {
        XCTAssertEqual(HKWorkoutActivityType.values["Running"], .running)
        XCTAssertEqual(HKWorkoutActivityType.values["Social Dance"], .socialDance)
    }
}
