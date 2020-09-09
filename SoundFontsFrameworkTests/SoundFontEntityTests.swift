// Copyright © 2020 Brad Howes. All rights reserved.

import XCTest
import SoundFontsFramework
import SoundFontInfoLib
import CoreData

class SoundFontEntityTests: XCTestCase {

    func testAddSoundFont() {
        doWhenCoreDataReady(#function) { cdth, context in
            XCTAssertEqual(try? SoundFontEntity.count(context), 0)
            SoundFontEntity(context: context, config: cdth.sf1)
            XCTAssertEqual(try? SoundFontEntity.count(context), 1)
        }
    }

    func testFetchSoundFonts() {
        doWhenCoreDataReady(#function) { cdth, context in
            SoundFontEntity(context: context, config: cdth.sf1)
            SoundFontEntity(context: context, config: cdth.sf2)
            SoundFontEntity(context: context, config: cdth.sf3)
            let soundFonts = cdth.fetchSoundFonts()
            XCTAssertNotNil(soundFonts)
            XCTAssertEqual(soundFonts?.count, 3)
            let sf1 = soundFonts![0]
            XCTAssertEqual(sf1.name, "one")
            XCTAssertEqual(sf1.presets.count, 4)
            let p1 = sf1.presets[0] as! PresetEntity
            XCTAssertNotNil(p1)
            XCTAssertEqual(p1.name, "One")
        }
    }
}
