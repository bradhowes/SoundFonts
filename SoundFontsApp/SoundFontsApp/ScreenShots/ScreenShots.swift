// Copyright © 2019 Brad Howes. All rights reserved.

import XCTest
//import SoundFontsFramework

class ScreenShots: XCTestCase {
  let timeout = 5.0
  var app: XCUIApplication!
  var effectsButton: XCUIElement!
  var suffix: String!

  func test01PresetsPortrait() { run(.portrait, "Presets") { showPresetsView() } }
  func test02FavoritesPortrait() { run(.portrait, "Favorites") { showFavoritesView() } }
  func test03SettingsPortrait() { run(.portrait, "Settings") { showSettingsView() } }
  func test04FontEditPortrait() { run(.portrait, "FontEdit") { showFontEditView() } }
  func test05PresetEditPortrait() { run(.portrait, "FavoriteEdit") { showPresetEditView() } }
  func test05ShowEffectsPortrait() { run(.portrait, "Effects") { showEffectsView() } }

  func test06PresetsLandscape() { run(.landscapeLeft, "Presets") { showPresetsView() } }
  func test07FavoritesLandscape() { run(.landscapeLeft, "Favorites") { showFavoritesView() } }
  func test08SettingsLandscape() { run(.landscapeLeft, "Settings") { showSettingsView() } }
  func test09FontEditLandscape() { run(.landscapeLeft, "FontEdit") { showFontEditView() } }
  func test10PresetEditLandscape() { run(.landscapeLeft, "FavoriteEdit") { showPresetEditView() } }
  func test11ShowEffectsLandscape() { run(.landscapeLeft, "Effects") { showEffectsView() } }

  func test12ShowTags() { run(.portrait, "Tags") { showTagsView() } }
  func test13TagsEdit() { run(.portrait, "TagsEdit") { showTagsEditView() } }
  func test14ShowWelcomeScreen() { run(.portrait, "Welcome") { showWelcomeScreen() } }
  func test15Search() { run(.portrait, "Search") { showSearch() } }

}

extension ScreenShots {

  func run(_ orientation: UIDeviceOrientation, _ title: String, setup: () -> Void) {
    initialize(orientation)
    setup()
    if !title.isEmpty {
      snap(title)
    }
  }

  func initialize(_ orientation: UIDeviceOrientation) {
    suffix = orientation.isPortrait ? "-Portrait" : "-Landscape"
    XCUIDevice.shared.orientation = orientation
    continueAfterFailure = false
    app = XCUIApplication()
    setupSnapshot(app)
    app.launch()

    showUpperView(name: "FontsCollection")

    effectsButton = app.buttons["Effects"]
    XCTAssert(effectsButton.waitForExistence(timeout: timeout))

    // Hide effects at start
    let reverb = app.buttons["ReverbToggle"]
    if reverb.exists && reverb.isHittable {
      app.buttons["Effects"].tap()
    }

    // Make sure that "MuseScore" font is available
    let entry = app.tables.staticTexts["font MuseScore"]
    if !entry.exists || !entry.isHittable {
      let tagsButton = app.buttons["Tags"]
      let tagsList = app.tables["TagsTableList"]
      if !tagsList.exists || !tagsList.isHittable {
        tagsButton.tap()
      }

      XCTAssert(tagsList.waitForExistence(timeout: timeout))

      // Select "All"
      let tag = app.tables.staticTexts["tag All"]
      tag.tap()

      // Hide the tags view
      tagsButton.tap()
    }
  }

  func snap(_ title: String) { snapshot(title + suffix) }

  func switchViews() {
    let touchView = app.otherElements["TouchView"]
    touchView.doubleTap()
  }

  func showUpperView(name: String) {
    let upperView = app.otherElements[name]
    guard upperView.exists == false else { return }
    switchViews()
    XCTAssert(upperView.waitForExistence(timeout: timeout), "failed to show view '\(name)'")
  }

  func showPresetsView() { showUpperView(name: "FontsCollection") }

  func showFavoritesView() { showUpperView(name: "FavoritesCollection") }

  func showSettingsView() {
    if app.buttons["More Right"].exists {
      app.buttons["More Right"].tap()
    }
    app.buttons["Settings"].tap()

    let settingsView = app.otherElements["SettingsView"]
    XCTAssert(settingsView.waitForExistence(timeout: timeout))
  }

  func showFontEditView() {
    showUpperView(name: "FontsCollection")
    let entry = app.tables.staticTexts["font MuseScore"]
    XCTAssert(entry.waitForExistence(timeout: timeout))
    entry.tap()
    entry.swipeRight()
    app.tables.buttons["Edit item"].tap()

    let fontEditor = app.navigationBars["SoundFont"]
    XCTAssert(fontEditor.waitForExistence(timeout: timeout))
  }

  func showTagsEditView() {
    showFontEditView()

    let editTags = app.buttons.staticTexts["Edit Tags"]
    XCTAssert(editTags.waitForExistence(timeout: timeout))
    editTags.tap()

    let tagsEditor = app.navigationBars["Tags"]
    XCTAssert(tagsEditor.waitForExistence(timeout: timeout))
  }

  func showPresetEditView() {
    showPresetsView()
    let entry = app.tables.staticTexts["font MuseScore"]
    XCTAssert(entry.waitForExistence(timeout: timeout))
    entry.tap()
    app.scrollToTop()

    let preset = app.tables.staticTexts["preset Electric Grand"]
    XCTAssert(preset.waitForExistence(timeout: timeout))
    preset.tap()
    preset.swipeRight()
    app.tables.buttons["Edit item"].tap()

    let presetEditor = app.navigationBars["Preset"]
    XCTAssert(presetEditor.waitForExistence(timeout: timeout))
  }

  func showTagsView() {
    let font = app.tables.staticTexts["font MuseScore"]
    font.tap()
    app.scrollToTop()

    let preset = app.tables.staticTexts["preset Tine Electric Piano"]
    XCTAssert(preset.waitForExistence(timeout: timeout))
    preset.tap()

    app.buttons["Tags"].tap()
    let tag = app.tables.staticTexts["tag All"]
    XCTAssert(tag.waitForExistence(timeout: timeout))
  }

  func showEffectsView() {
    print(app.debugDescription)
    let font = app.tables.staticTexts["font MuseScore"]
    XCTAssert(font.waitForExistence(timeout: timeout))

    let reverb = app.buttons["ReverbToggle"]

    font.tap()
    app.scrollToTop()

    let preset = app.tables.staticTexts["preset Stereo Grand"]
    XCTAssert(preset.waitForExistence(timeout: timeout))
    preset.tap()

    app.buttons["Effects"].tap()
    XCTAssert(reverb.waitForExistence(timeout: timeout))
  }

  func showWelcomeScreen() {
    if app.buttons["More Right"].exists {
      app.buttons["More Right"].tap()
    }
    app.buttons["Settings"].tap()
    let settingsView = app.otherElements["SettingsView"]
    XCTAssert(settingsView.waitForExistence(timeout: timeout))
    let show = settingsView.buttons["ShowTutorial"]
    XCTAssert(show.waitForExistence(timeout: timeout))
    show.tap()
    XCTAssert(app.buttons["Done"].waitForExistence(timeout: timeout))
  }

  func showSearch() {
    let sectionIndex = app.otherElements["Section index"]
    XCTAssert(sectionIndex.waitForExistence(timeout: timeout))
    sectionIndex.tap()

    print(app.debugDescription)
    let searchField = app.searchFields["Name"]
    XCTAssert(searchField.waitForExistence(timeout: timeout))
    searchField.typeText("Harp")
    let preset = app.tables.staticTexts["preset Harpsi Pad"]
    XCTAssert(preset.waitForExistence(timeout: timeout))
    // preset.tap()
  }
}

extension XCUIApplication {
  private struct Constants {
    // Half way across the screen and 10% from top
    static let topOffset = CGVector(dx: 0.5, dy: 0.1)

    // Half way across the screen and 90% from top
    static let bottomOffset = CGVector(dx: 0.5, dy: 0.9)
  }

  var screenTopCoordinate: XCUICoordinate {
    windows.firstMatch.coordinate(withNormalizedOffset: Constants.topOffset)
  }

  var screenBottomCoordinate: XCUICoordinate {
    windows.firstMatch.coordinate(withNormalizedOffset: Constants.bottomOffset)
  }

  func scrollDownToElement(element: XCUIElement, maxScrolls: Int = 5) {
    for _ in 0..<maxScrolls {
      if element.exists && element.isHittable { element.scrollToTop(); break }
      scrollDown()
    }
  }

  func scrollDown() {
    screenBottomCoordinate.press(forDuration: 0.1, thenDragTo: screenTopCoordinate)
  }
}

extension XCUIElement {
  func scrollToTop() {
    let topCoordinate = XCUIApplication().screenTopCoordinate
    let elementCoordinate = coordinate(withNormalizedOffset: .zero)

    // Adjust coordinate so that the drag is straight up, otherwise
    // an embedded horizontal scrolling element will get scrolled instead
    let delta = topCoordinate.screenPoint.x - elementCoordinate.screenPoint.x
    let deltaVector = CGVector(dx: delta, dy: 0.0)

    elementCoordinate.withOffset(deltaVector).press(forDuration: 0.1, thenDragTo: topCoordinate)
  }
}
