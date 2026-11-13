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

    func testOnboardingSavesFiveSessionPlanWithFourTrainingDays() {
        let app = XCUIApplication()
        app.launchArguments.append("--sendo-fixtures")
        app.launchEnvironment["SENDO_WORKOUT_STORE_ID"] = UUID().uuidString
        app.launch()

        let bodyweight = app.buttons["Bodyweight"]
        XCTAssertTrue(bodyweight.waitForExistence(timeout: 5))
        let wordmark = app.staticTexts["sendo.wordmark"]
        XCTAssertTrue(wordmark.isHittable)
        XCTAssertEqual(wordmark.label, "Sendo")
        capture(app, named: "Training setup")
        bodyweight.tap()
        app.buttons["Continue"].tap()
        let template = app.buttons["Use a template"]
        XCTAssertTrue(template.waitForExistence(timeout: 5))
        template.tap()
        let finish = app.buttons["onboarding.finish"]
        XCTAssertTrue(finish.waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons.matching(identifier: "workout.planEditor.session").count, 5)
        capture(app, named: "Review your plan")
        if !finish.isHittable { app.scrollViews.firstMatch.swipeUp() }
        finish.tap()

        let saved = app.staticTexts["workout.nextSummary"]
        XCTAssertTrue(saved.waitForExistence(timeout: 5))
        XCTAssertTrue(saved.label.contains("Session 1 of 5 · 4 training days per week"))
        capture(app, named: "Workout ready")
        app.terminate()
        app.launch()
        XCTAssertTrue(saved.waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Set up your training"].exists)

        app.tabBars.buttons["Profile"].tap()
        app.buttons["Edit training preferences"].tap()
        XCTAssertTrue(app.buttons["Save preferences"].waitForExistence(timeout: 5))
        app.buttons["onboarding.trainingDays"].tap()
        app.buttons["3 days"].tap()
        app.buttons["Save preferences"].tap()
        app.tabBars.buttons["Workout"].tap()
        XCTAssertTrue(saved.waitForExistence(timeout: 5))
        XCTAssertTrue(saved.label.contains("Session 1 of 5 · 3 training days per week"))
    }

    func testGuestCreatesReopensAndEditsWorkoutPlan() {
        let app = XCUIApplication()
        app.launchArguments.append("--sendo-fixtures")
        app.launchEnvironment["SENDO_WORKOUT_STORE_ID"] = UUID().uuidString
        app.launch()
        deferTrainingSetup(in: app)
        app.tabBars.buttons["Workout"].tap()

        XCTAssertTrue(app.buttons["Create a plan"].waitForExistence(timeout: 5))
        app.buttons["Set up training"].tap()
        app.buttons["Continue"].tap()
        app.buttons["Build manually"].tap()
        app.buttons["Add a session"].tap()
        app.tables.staticTexts["Add exercise"].tap()

        let search = app.searchFields["Search exercises"]
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("squat")
        let squat = app.tables.staticTexts["Bodyweight Squat"]
        XCTAssertTrue(squat.waitForExistence(timeout: 5))
        squat.tap()

        let saveExercise = app.buttons["workout.saveExercise"]
        XCTAssertTrue(saveExercise.waitForExistence(timeout: 5))
        saveExercise.tap()
        XCTAssertTrue(squat.waitForExistence(timeout: 5))
        app.navigationBars.buttons["workout.saveSession"].tap()
        app.buttons["onboarding.finish"].tap()
        XCTAssertTrue(app.staticTexts["My workout plan · Session 1 of 1 · 4 training days per week"].waitForExistence(timeout: 5))

        app.terminate()
        app.launch()
        app.tabBars.buttons["Workout"].tap()
        let editPlan = app.buttons["Edit plan"]
        XCTAssertTrue(editPlan.waitForExistence(timeout: 5))
        editPlan.tap()
        app.buttons["workout.planEditor.session"].tap()
        squat.tap()
        app.buttons["Swap exercise"].tap()

        let lunge = app.tables.staticTexts["Reverse Lunge"]
        XCTAssertTrue(lunge.waitForExistence(timeout: 5))
        lunge.tap()
        XCTAssertTrue(saveExercise.waitForExistence(timeout: 5))
        let load = app.textFields["workout.startingLoad"]
        if !load.isHittable { app.scrollViews.firstMatch.swipeUp() }
        load.tap()
        load.typeText("20")
        saveExercise.tap()
        XCTAssertTrue(lunge.waitForExistence(timeout: 5))
        app.navigationBars.buttons["workout.saveSession"].tap()
        app.buttons["workout.savePlan"].tap()

        XCTAssertTrue(editPlan.waitForExistence(timeout: 5))
        editPlan.tap()
        app.buttons["workout.planEditor.session"].tap()
        XCTAssertTrue(lunge.waitForExistence(timeout: 5))
        XCTAssertTrue(app.tables.staticTexts["3 × 8–12 reps · 20 kg"].exists)
    }

    func testExercisesTabOpens() {
        let app = launchApp()
        app.tabBars.buttons["Exercises"].tap()

        XCTAssertTrue(app.staticTexts["Exercises"].exists)
        XCTAssertTrue(app.buttons["catalog.exercise.fixture-squat"].waitForExistence(timeout: 5))
    }

    func testProgressOpensWeightFormAndCancels() {
        let app = launchApp()
        app.tabBars.buttons["Progress"].tap()
        app.buttons["progress.addMeasurement"].tap()

        let cancel = app.navigationBars.buttons["Cancel"]
        XCTAssertTrue(cancel.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Date"].exists)
        XCTAssertTrue(app.staticTexts["Value"].exists)
        cancel.tap()

        XCTAssertTrue(app.buttons["progress.addMeasurement"].exists)
    }

    func testProfileTogglesDarkMode() {
        let app = launchApp()
        app.tabBars.buttons["Profile"].tap()
        let toggle = app.buttons["profile.darkMode"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        let before = toggle.label
        toggle.tap()
        XCTAssertNotEqual(toggle.label, before)
        toggle.tap()
        XCTAssertEqual(toggle.label, before)
    }

    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments.append("--sendo-fixtures")
        app.launch()
        deferTrainingSetup(in: app)
        return app
    }

    private func capture(_ app: XCUIApplication, named name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func deferTrainingSetup(in app: XCUIApplication) {
        let later = app.buttons["Set up later"]
        XCTAssertTrue(later.waitForExistence(timeout: 5))
        later.tap()
    }
}
