//
//  sendoUITests.swift
//  sendoUITests
//
//  Created by Aimar Ugarte on 23/10/21.
//

import XCTest

final class SendoUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testWorkoutOpensPlannerAndSession() {
        let app = launchApp()
        app.tabBars.buttons["Workout"].tap()
        app.buttons["Plan your workout"].tap()

        XCTAssertTrue(app.navigationBars["New Workout"].exists)
        let session = app.tables.cells.firstMatch
        XCTAssertTrue(session.exists)
        session.tap()

        XCTAssertTrue(app.navigationBars["Session"].exists)
    }

    func testExercisesTabOpens() {
        let app = launchApp()
        app.tabBars.buttons["Exercises"].tap()

        XCTAssertTrue(app.navigationBars["Exercises"].exists)
        XCTAssertTrue(app.tables.firstMatch.exists)
    }

    func testProgressOpensWeightFormAndCancels() {
        let app = launchApp()
        app.tabBars.buttons["Progress"].tap()
        app.navigationBars["Progress"].buttons["progress.addMeasurement"].tap()

        let cancel = app.navigationBars.buttons["Cancel"]
        XCTAssertTrue(cancel.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Date"].exists)
        XCTAssertTrue(app.staticTexts["Value"].exists)
        cancel.tap()

        XCTAssertTrue(app.navigationBars["Progress"].exists)
    }

    func testProfileOpensSettings() {
        let app = launchApp()
        app.tabBars.buttons["Profile"].tap()
        app.buttons["profile.settings"].tap()

        XCTAssertTrue(app.navigationBars["Settings"].exists)
        XCTAssertTrue(app.staticTexts["Dark mode"].exists)
        XCTAssertTrue(app.switches.firstMatch.exists)
    }

    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()
        return app
    }
}
