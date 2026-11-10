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

    func testGuestCreatesReopensAndEditsWorkoutPlan() {
        let app = XCUIApplication()
        app.launchArguments.append("--sendo-fixtures")
        app.launchEnvironment["SENDO_WORKOUT_STORE_ID"] = UUID().uuidString
        app.launch()
        app.tabBars.buttons["Workout"].tap()

        let createPlan = app.buttons["Create a plan"]
        XCTAssertTrue(createPlan.waitForExistence(timeout: 5))
        createPlan.tap()
        app.tables.staticTexts["Add session"].tap()
        app.tables.staticTexts["Add exercise"].tap()

        let search = app.searchFields["Search exercises"]
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("squat")
        let squat = app.tables.staticTexts["Bodyweight Squat"]
        XCTAssertTrue(squat.waitForExistence(timeout: 5))
        squat.tap()

        let saveExercise = app.navigationBars.buttons["workout.saveExercise"]
        XCTAssertTrue(saveExercise.waitForExistence(timeout: 5))
        saveExercise.tap()
        XCTAssertTrue(squat.waitForExistence(timeout: 5))
        app.navigationBars.buttons["workout.saveSession"].tap()
        app.navigationBars.buttons["Save"].tap()
        XCTAssertTrue(app.staticTexts["My workout plan · Session 1 of 1"].waitForExistence(timeout: 5))

        app.terminate()
        app.launch()
        app.tabBars.buttons["Workout"].tap()
        let editPlan = app.navigationBars.buttons["Edit plan"]
        XCTAssertTrue(editPlan.waitForExistence(timeout: 5))
        editPlan.tap()
        app.tables.cells["workout.planEditor.session"].tap()
        squat.tap()
        app.tables.staticTexts["Swap exercise"].tap()

        let lunge = app.tables.staticTexts["Reverse Lunge"]
        XCTAssertTrue(lunge.waitForExistence(timeout: 5))
        lunge.tap()
        XCTAssertTrue(saveExercise.waitForExistence(timeout: 5))
        let load = app.textFields["workout.startingLoad"]
        if !load.isHittable { app.tables.firstMatch.swipeUp() }
        load.tap()
        load.typeText("20")
        saveExercise.tap()
        XCTAssertTrue(lunge.waitForExistence(timeout: 5))
        app.navigationBars.buttons["workout.saveSession"].tap()
        app.navigationBars.buttons["Save"].tap()

        XCTAssertTrue(editPlan.waitForExistence(timeout: 5))
        editPlan.tap()
        app.tables.cells["workout.planEditor.session"].tap()
        XCTAssertTrue(lunge.waitForExistence(timeout: 5))
        XCTAssertTrue(app.tables.staticTexts["3 × 8–12 reps · 20 kg"].exists)
    }

    func testExercisesTabOpens() {
        let app = launchApp()
        app.tabBars.buttons["Exercises"].tap()

        XCTAssertTrue(app.navigationBars["Exercises"].exists)
        XCTAssertTrue(app.tables.staticTexts["Bodyweight Squat"].waitForExistence(timeout: 5))
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
        app.launchArguments.append("--sendo-fixtures")
        app.launch()
        return app
    }
}
