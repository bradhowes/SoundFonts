// Copyright © 2019 Brad Howes. All rights reserved.

import XCTest
//import SoundFontsFramework

class ScreenShots: XCTestCase {
  let timeout = 5.0
  var app: XCUIApplication!
  var suffix: String!

  //  func test01PresetsPortrait() { run(.portrait, "Presets") { showPresetsView() } }
  //  func test02FavoritesPortrait() { run(.portrait, "Favorites") { showFavoritesView() } }
  //  func test03SettingsPortrait() { run(.portrait, "Settings") { showSettingsView() } }
  //  func test04FontEditPortrait() { run(.portrait, "FontEdit") { showFontEditView() } }
  //  func test05PresetEditPortrait() { run(.portrait, "FavoriteEdit") { showPresetEditView() } }
  //  func test05ShowEffectsPortrait() { run(.portrait, "Effects") { showEffectsView() } }
  //
  //  func test06PresetsLandscape() { run(.landscapeLeft, "Presets") { showPresetsView() } }
  //  func test07FavoritesLandscape() { run(.landscapeLeft, "Favorites") { showFavoritesView() } }
  //  func test08SettingsLandscape() { run(.landscapeLeft, "Settings") { showSettingsView() } }
  //  func test09FontEditLandscape() { run(.landscapeLeft, "FontEdit") { showFontEditView() } }
  //  func test10PresetEditLandscape() { run(.landscapeLeft, "FavoriteEdit") { showPresetEditView() } }
  //  func test11ShowEffectsLandscape() { run(.landscapeLeft, "Effects") { showEffectsView() } }
  //
  //  func test12ShowTags() { run(.portrait, "Tags") { showTagsView() } }
  //  func test13TagsEdit() { run(.portrait, "TagsEdit") { showTagsEditView() } }
  //  func test14ShowWelcomeScreen() { run(.portrait, "Welcome") { showWelcomeScreen() } }
  //  func test15Search() { run(.portrait, "Search") { showSearch() } }
  //

  func testPlaySequence() {
    XCUIDevice.shared.orientation = .portrait
    continueAfterFailure = false

    app = XCUIApplication()
    app.launch()

    showUpperView(name: "FavoritesCollection")

    // let effectsButton = app.buttons["Effects"]
    let preset1 = app.staticTexts["favorite Ambiance"]
    let preset2 = app.staticTexts["favorite Tribal 5th"]
    let preset3 = app.staticTexts["favorite PAd 2"]
    let preset4 = app.staticTexts["favorite BowedG"]
    let preset5 = app.staticTexts["favorite Ice Rain Cometh"]
    let preset6 = app.staticTexts["favorite Shakuhachi  Max"]
    let preset7 = app.staticTexts["favorite Synclavier"]

    preset1.tap()
    let C6 = app.otherElements["C6"]
    Thread.sleep(forTimeInterval: 0.125)
    C6.press(forDuration: 2.0)
    Thread.sleep(forTimeInterval: 1.5)

    preset2.tap()
    let F4 = app.otherElements["F4"]
    Thread.sleep(forTimeInterval: 0.125)
    F4.press(forDuration: 1.0)
    Thread.sleep(forTimeInterval: 1.5)

    preset3.tap()
    let C4 = app.otherElements["C4"]
    Thread.sleep(forTimeInterval: 0.125)
    C4.press(forDuration: 1.0)
    Thread.sleep(forTimeInterval: 1.5)

    preset4.tap()
    let F5 = app.otherElements["F5"]
    let E5 = app.otherElements["E5"]
    let D5 = app.otherElements["D5"]
    let C5 = app.otherElements["C5"]
    F5.press(forDuration: 0.125)
    E5.press(forDuration: 0.125)
    D5.press(forDuration: 0.125)
    C5.press(forDuration: 0.125)
    Thread.sleep(forTimeInterval: 0.5)

    preset5.tap()
    let C2 = app.otherElements["C2"]
    let E2 = app.otherElements["E2"]
    Thread.sleep(forTimeInterval: 0.125)
    C2.press(forDuration: 1.0)
    E2.press(forDuration: 1.0)
    Thread.sleep(forTimeInterval: 1.0)

    preset6.tap()
    let F2 = app.otherElements["F2"]
    Thread.sleep(forTimeInterval: 0.125)
    F2.press(forDuration: 0.125)
    Thread.sleep(forTimeInterval: 0.5)

    preset7.tap()
    Thread.sleep(forTimeInterval: 0.125)
    C5.press(forDuration: 0.25)
    Thread.sleep(forTimeInterval: 2.0)
  }

  func test01PortraitSnaps() { snapshotDriver(.portrait) }
  func test02LandscapeSnaps() { snapshotDriver(.landscapeLeft) }

  func snapshotDriver(_ orientation: UIDeviceOrientation) {
    initialize(orientation)

    let font = app.tables.staticTexts["font MuseScore"]
    XCTAssert(font.waitForExistence(timeout: timeout))
    font.tap()

    let preset = app.tables.staticTexts["preset Bright Grand"]
    XCTAssert(preset.waitForExistence(timeout: timeout))
    preset.tap()

    snap("Presets")

    font.tap()
    font.swipeRight()
    app.tables.buttons["Edit item"].tap()

    let fontEditor = app.navigationBars["SoundFont"]
    XCTAssert(fontEditor.waitForExistence(timeout: timeout))

    snap("FontEditor")

    let editTags = app.buttons.staticTexts["Edit Tags"]
    XCTAssert(editTags.waitForExistence(timeout: timeout))
    editTags.tap()

    let tagsEditor = app.navigationBars["Tags"]
    XCTAssert(tagsEditor.waitForExistence(timeout: timeout))

    snap("TagsEditor")

    print(tagsEditor.debugDescription)
    let backButton = tagsEditor.buttons["SoundFont"]
    backButton.tap()

    let doneButton = app.buttons["Done"]
    doneButton.tap()

    preset.tap()
    preset.swipeRight()
    app.tables.buttons["Edit item"].tap()

    let presetEditor = app.navigationBars["Preset"]
    XCTAssert(presetEditor.waitForExistence(timeout: timeout))

    snap("PresetEditor")

    let cancelButton = presetEditor.buttons["Cancel"]
    cancelButton.tap()

    let tagsButton = app.buttons["Tags"]
    tagsButton.tap()

    let tagsList = app.tables["TagsTableList"]
    XCTAssert(tagsList.waitForExistence(timeout: timeout))

    let lfrp = tagsList.staticTexts["tag LFRP"]
    lfrp.tap()

    if orientation == .portrait {
      snap("Tags")
    }

    tagsList.staticTexts["tag All"].tap()
    tagsButton.tap()

    let effectsButton = app.buttons["Effects"]
    effectsButton.tap()

    let enableReverb = app.buttons["EnableReverbEffect"]
    if enableReverb.exists && enableReverb.isHittable {
      enableReverb.tap()
    }
    let disableReverb = app.buttons["DisableReverbEffect"]

    let enableDelay = app.buttons["EnableDelayEffect"]
    if enableDelay.exists && enableDelay.isHittable {
      enableDelay.tap()
    }
    let disableDelay = app.buttons["DisableDelayEffect"]

    if orientation == .portrait {
      snap("Effects")
    }

    disableReverb.tap()
    disableDelay.tap()
    effectsButton.tap()

    if app.buttons["More Right"].exists {
      app.buttons["More Right"].tap()
    }
    app.buttons["Settings"].tap()

    let settingsView = app.otherElements["SettingsView"]
    XCTAssert(settingsView.waitForExistence(timeout: timeout))

    snap("Settings")

    let showTutorial = settingsView.buttons["ShowTutorial"]
    XCTAssert(showTutorial.waitForExistence(timeout: timeout))
    showTutorial.tap()
    XCTAssert(app.buttons["Done"].waitForExistence(timeout: timeout))

    snap("Welcome")

    app.buttons["Done"].tap()

    if orientation == .portrait {

      let sectionIndex = app.otherElements["Section index"]
      XCTAssert(sectionIndex.waitForExistence(timeout: timeout))
      sectionIndex.tap()

      let searchField = app.searchFields["Name"]
      XCTAssert(searchField.waitForExistence(timeout: timeout))
      searchField.typeText("Harp")
      let presetHarpsiPad = app.tables.staticTexts["preset Harpsi Pad"]
      XCTAssert(presetHarpsiPad.waitForExistence(timeout: timeout))

      snap("Search")
    }

    // Switch to Favorites view

    let touchView = app.otherElements["TouchView"]
    touchView.doubleTap()

    let favorite = app.staticTexts["favorite Overdrive"]
    XCTAssert(favorite.waitForExistence(timeout: timeout))
    favorite.tap()

    snap("Favorites")

    favorite.doubleTap()

    let favoriteEditor = app.navigationBars["Favorite"]
    XCTAssert(favoriteEditor.waitForExistence(timeout: timeout))

    snap("FavoriteEditor")

    favoriteEditor.buttons["Cancel"].tap()

    // Show help screen

    if app.buttons["More Right"].exists {
      app.buttons["More Right"].tap()
    }
    app.buttons["Help"].tap()

    snap("Help")
  }
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

    let effectsButton = app.buttons["Effects"]
    XCTAssert(effectsButton.waitForExistence(timeout: timeout))

    // Hide effects at start
    let reverbEnable = app.buttons["EnableReverbEffect"]
    let reverbDisable = app.buttons["DisableReverbEffect"]
    if reverbEnable.exists && reverbEnable.isHittable || reverbDisable.exists && reverbDisable.isHittable {
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

  func showPresetsView() {
    showUpperView(name: "FontsCollection")

    let font = app.tables.staticTexts["font MuseScore"]
    XCTAssert(font.waitForExistence(timeout: timeout))
    font.tap()

    let preset = app.tables.staticTexts["preset Bright Grand"]
    XCTAssert(preset.waitForExistence(timeout: timeout))
    preset.tap()
  }

  func showFavoritesView() {
    showUpperView(name: "FavoritesCollection")
    print(app.debugDescription)
    let favorite = app.staticTexts["favorite Overdrive"]
    XCTAssert(favorite.waitForExistence(timeout: timeout))
    favorite.tap()
  }

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
    let font = app.tables.staticTexts["font MuseScore"]
    XCTAssert(font.waitForExistence(timeout: timeout))
    font.tap()

    let preset = app.tables.staticTexts["preset Bright Grand"]
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

    let preset = app.tables.staticTexts["preset Bright Grand"]
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
    font.tap()

    let preset = app.tables.staticTexts["preset Bright Grand"]
    XCTAssert(preset.waitForExistence(timeout: timeout))
    preset.tap()

    app.buttons["Effects"].tap()
    let reverb = app.buttons["ReverbToggle"]
    print(reverb.debugDescription)
    XCTAssert(reverb.waitForExistence(timeout: timeout))
    reverb.tap()
    let delay = app.buttons["DelayToggle"]
    delay.tap()
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
