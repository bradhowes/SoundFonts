// Copyright © 2020 Brad Howes. All rights reserved.

import XCTest
import SoundFontsFramework

class NoteTests: XCTestCase {

    func testNotes() {
        XCTAssertEqual("C-1", Note(midiNoteValue: 0).label)
        XCTAssertEqual("A4", Note(midiNoteValue: 69).label)
    }

//    func testPerformanceExample() {
//        self.measure {
//        }
//    }
}
