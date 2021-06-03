// Copyright © 2020 Brad Howes. All rights reserved.

@testable import SoundFontsFramework
import XCTest

class BundleTests: XCTestCase {

  func testVersions() {
    let bundle = Bundle(for: SoundFont.self)
    XCTAssertEqual(bundle.bundleIdentifier, "com.braysoftware.SoundFontsFramework")

    let buildVersionNumber = bundle.buildVersionNumber
    XCTAssertEqual(buildVersionNumber.count, 14)

    let releaseVersionNumber = bundle.releaseVersionNumber
    let components = releaseVersionNumber.split(separator: ".")
    XCTAssertEqual(components.count, 3)
    XCTAssertFalse(components[0].isEmpty)
    XCTAssertFalse(components[1].isEmpty)
    XCTAssertFalse(components[2].isEmpty)

    XCTAssertEqual(bundle.versionString, "Version \(releaseVersionNumber).\(buildVersionNumber)")
  }

  func testStringForKey() {
    let bundle = Bundle(for: SoundFont.self)
    XCTAssertEqual(bundle.string(forKey: "  "), "")
    XCTAssertEqual(bundle.string(forKey: "UIAppFonts"), "")
  }

  func testEffectsButtonImage() {
    XCTAssertNoThrow(Bundle.effectEnabledButtonImage(enabled: false))
    XCTAssertNoThrow(Bundle.effectEnabledButtonImage(enabled: true))
  }
}
