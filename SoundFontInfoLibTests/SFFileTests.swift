// Copyright © 2019 Brad Howes. All rights reserved.

import XCTest
import SoundFontInfoLib

class SFFileTests: XCTestCase {

    func urlNamed(_ name: String) -> URL { Bundle(for: type(of: SFFileTests)).url(forResource: name, withExtension: "sf2")! }

    var soundFont1: URL { urlNamed("FluidR3_GM") }
    var soundFont2: URL { urlNamed("FreeFont") }
    var soundFont3: URL { urlNamed("GeneralUser GS MuseScore v1.442") }
    var soundFont4: URL { urlNamed("RolandNicePiano") }
    var soundFonts: [URL] { [soundFont1, soundFont2, soundFont3, soundFont4] }

    func testInit() {
        for url in soundFonts {
            let _ = SoundFontInfo.load(url)
        }
    }
}
