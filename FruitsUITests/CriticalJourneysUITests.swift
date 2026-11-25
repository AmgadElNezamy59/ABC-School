import XCTest

/// The three journeys a family uses every day: browse and listen, play a game, manage settings.
/// Runs with `-ui-testing`: a fresh progress store and no animations.
final class CriticalJourneysUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testHomeShowsEveryTopic() {
        let app = launchApp()
        XCTAssertTrue(app.navigationBars["ABC School"].waitForExistence(timeout: 5))
        for topic in ["alphabet", "fruits", "animals", "colors", "numbers", "shapes"] {
            XCTAssertTrue(app.buttons["topic.\(topic)"].waitForExistence(timeout: 2), "Missing topic \(topic)")
        }
    }

    @MainActor
    func testBrowseATopicAndItsWordCards() {
        let app = launchApp()
        app.buttons["topic.fruits"].tap()
        XCTAssertTrue(app.navigationBars["Fruits"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["topic.learn"].exists)
        XCTAssertTrue(app.buttons["topic.play"].exists)

        // Open the second word directly from the grid.
        app.buttons["word.fruits.banana"].tap()
        let counter = app.staticTexts["learn.counter"]
        XCTAssertTrue(counter.waitForExistence(timeout: 3))
        XCTAssertEqual(counter.label, "2 of 12")
        XCTAssertTrue(app.staticTexts["Banana"].exists)

        app.buttons["learn.next"].tap()
        XCTAssertTrue(app.staticTexts["Strawberry"].waitForExistence(timeout: 3))
        XCTAssertEqual(counter.label, "3 of 12")

        app.buttons["learn.previous"].tap()
        XCTAssertEqual(counter.label, "2 of 12")

        // Every control does something real and nothing gets stuck.
        app.buttons["learn.listen"].tap()
        app.buttons["learn.slow"].tap()
        let sentences = app.buttons.matching(identifier: "learn.sentence")
        let visibleSentence = (0..<sentences.count).map { sentences.element(boundBy: $0) }.first { $0.isHittable }
        XCTAssertNotNil(visibleSentence, "The current card should show its sentence")
        visibleSentence?.tap()

        // Say it opens practice; closing it returns to the same card.
        app.buttons["learn.sayIt"].tap()
        let done = app.buttons["practice.done"]
        XCTAssertTrue(done.waitForExistence(timeout: 3))
        done.tap()
        XCTAssertTrue(counter.waitForExistence(timeout: 3))
        XCTAssertEqual(counter.label, "2 of 12")
    }

    @MainActor
    func testFirstCardCannotGoBackAndLastCannotGoForward() {
        let app = launchApp()
        app.buttons["topic.shapes"].tap()
        app.buttons["word.shapes.circle"].tap()
        XCTAssertTrue(app.buttons["learn.previous"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["learn.previous"].isEnabled)

        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons["word.shapes.oval"].tap()
        XCTAssertTrue(app.buttons["learn.next"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["learn.next"].isEnabled)
    }

    @MainActor
    func testPlayAWholeListenAndFindGame() {
        let app = launchApp()
        app.buttons["topic.animals"].tap()
        app.buttons["topic.play"].tap()

        let round = app.staticTexts["game.round"]
        XCTAssertTrue(round.waitForExistence(timeout: 3))

        for expectedRound in 1...8 {
            XCTAssertTrue(round.waitForExistence(timeout: 5), "Round \(expectedRound) never appeared")
            XCTAssertEqual(round.label, "Round \(expectedRound) of 8")
            solveCurrentRound(in: app)
            if expectedRound < 8 {
                let next = NSPredicate(format: "label == %@", "Round \(expectedRound + 1) of 8")
                expectation(for: next, evaluatedWith: round)
                waitForExpectations(timeout: 5)
            }
        }

        XCTAssertTrue(app.buttons["game.playAgain"].waitForExistence(timeout: 5))
        let results = XCTAttachment(screenshot: app.screenshot())
        results.name = "Game results"
        results.lifetime = .keepAlways
        add(results)
        app.buttons["game.done"].tap()

        // The best score now shows on the topic.
        let bestScore = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS 'Best game'")).firstMatch
        XCTAssertTrue(bestScore.waitForExistence(timeout: 3))
    }

    @MainActor
    func testLeavingAGameMidwayAsksFirst() {
        let app = launchApp()
        app.buttons["topic.colors"].tap()
        app.buttons["topic.play"].tap()
        XCTAssertTrue(app.staticTexts["game.round"].waitForExistence(timeout: 3))
        solveCurrentRound(in: app)

        app.buttons["game.close"].tap()
        let keepPlaying = app.alerts.buttons["Keep Playing"]
        XCTAssertTrue(keepPlaying.waitForExistence(timeout: 3))
        keepPlaying.tap()
        XCTAssertTrue(app.staticTexts["game.round"].exists)

        app.buttons["game.close"].tap()
        app.alerts.buttons["Leave Game"].tap()
        XCTAssertTrue(app.buttons["topic.play"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testSettingsChangeAndResetProgress() {
        let app = launchApp()
        app.buttons["home.settings"].tap()
        let autoplay = app.switches["settings.autoplay"]
        XCTAssertTrue(autoplay.waitForExistence(timeout: 3))
        let before = autoplay.value as? String
        // Tap the switch itself, at the trailing edge of the row.
        autoplay.coordinate(withNormalizedOffset: CGVector(dx: 0.93, dy: 0.5)).tap()
        XCTAssertNotEqual(autoplay.value as? String, before)

        app.buttons["settings.reset"].tap()
        let confirm = app.buttons
            .matching(NSPredicate(format: "label == 'Reset Progress' AND identifier != 'settings.reset'"))
            .firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: 3))
        confirm.tap()
        XCTAssertFalse(confirm.waitForExistence(timeout: 1))

        app.buttons["settings.done"].tap()
        XCTAssertTrue(app.navigationBars["ABC School"].waitForExistence(timeout: 3))
    }

    // MARK: Helpers

    @MainActor
    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()
        return app
    }

    /// Taps options until one is accepted, exactly like a child would.
    @MainActor
    private func solveCurrentRound(in app: XCUIApplication) {
        let options = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'game.option.'"))
        XCTAssertTrue(options.firstMatch.waitForExistence(timeout: 3))
        for index in 0..<options.count {
            let option = options.element(boundBy: index)
            guard option.isEnabled else { continue }
            option.tap()
            // Each option announces its result through its accessibility value.
            if option.value as? String == "Correct" { return }
        }
        XCTFail("No option was accepted as correct")
    }
}
