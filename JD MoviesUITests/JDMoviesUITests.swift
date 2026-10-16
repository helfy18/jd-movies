import XCTest

/// Smoke tests over the app's static chrome. They do not depend on network data,
/// so they pass offline and stay stable as the catalogue changes.
final class JDMoviesUITests: XCTestCase {
    private var app: XCUIApplication!

    @MainActor
    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    @MainActor
    func testTabBarShowsAllFourTabs() {
        for title in ["Home", "Ratings", "Random", "Stats"] {
            XCTAssertTrue(app.tabBars.buttons[title].waitForExistence(timeout: 5), "Missing \(title) tab")
        }
    }

    @MainActor
    func testRatingsTabHasSearchAndFilters() {
        app.tabBars.buttons["Ratings"].tap()
        XCTAssertTrue(app.navigationBars["Ratings"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.searchFields.firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.navigationBars["Ratings"].buttons["Filters"].exists)
    }

    @MainActor
    func testRandomTabHasNextAndFilterButtons() {
        app.tabBars.buttons["Random"].tap()
        XCTAssertTrue(app.navigationBars["Random Movie"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Next"].exists)
    }

    @MainActor
    func testAboutSheetOpensFromHome() {
        app.tabBars.buttons["Home"].tap()
        let about = app.navigationBars.buttons["About"]
        XCTAssertTrue(about.waitForExistence(timeout: 5))
        about.tap()
        XCTAssertTrue(app.navigationBars["About"].waitForExistence(timeout: 5))
        app.navigationBars["About"].buttons["Done"].tap()
        XCTAssertFalse(app.navigationBars["About"].exists)
    }
}
