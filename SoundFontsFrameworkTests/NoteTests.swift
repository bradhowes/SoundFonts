// Copyright © 2020 Brad Howes. All rights reserved.

import XCTest
import SoundFontsFramework

class NoteTests: XCTestCase {

    func testNotes() {
        XCTAssertEqual("C0", Note(midiNoteValue: 0).label)
    }

//    func testPerformanceExample() {
//        self.measure {
//        }
//    }
}
