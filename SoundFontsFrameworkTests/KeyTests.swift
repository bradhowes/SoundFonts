// Copyright © 2020 Brad Howes. All rights reserved.

import XCTest
@testable import SoundFontsFramework

class KeyTests: XCTestCase {

    func makeKeys() -> [Key] {
        let gen = KeyParamsSequence(keyWidth: 64.0, keyHeight: 100.0, firstMidiNote: 24, lastMidiNote: 35)
        let keyDefs = [KeyParamsSequence.Element](gen)
        return keyDefs.map { Key(frame: $0.0, note: $0.1) }
    }

    func testKey() {
        let key = Key(frame: CGRect(x: 0.0, y: 0.0, width: 64.0, height: 100.0), note: Note(midiNoteValue: 69))
        XCTAssertEqual("Key(A4,false)", key.description)
        XCTAssertTrue(key.frame.contains(CGPoint(x: 0.0, y: 0.0)))
        XCTAssertFalse(key.frame.contains(CGPoint(x: 64.0, y: 0.0)))
    }

    func testKeyCollectionOrderedInsertionIndex() {
        let keys = makeKeys()
        XCTAssertEqual(12, keys.count)
        XCTAssertEqual(0, keys.orderedInsertionIndex(for: CGPoint.zero))
        XCTAssertEqual(0, keys.orderedInsertionIndex(for: CGPoint(x: 37, y: 0))) // C
        XCTAssertEqual(1, keys.orderedInsertionIndex(for: CGPoint(x: 38, y: 0))) // C#
        XCTAssertEqual(0, keys.orderedInsertionIndex(for: CGPoint(x: 38, y: 60))) // C
        XCTAssertEqual(1, keys.orderedInsertionIndex(for: CGPoint(x: 89, y: 0))) // C#
        XCTAssertEqual(2, keys.orderedInsertionIndex(for: CGPoint(x: 89, y: 60))) // D
        XCTAssertEqual(2, keys.orderedInsertionIndex(for: CGPoint(x: 90, y: 0))) // D

        XCTAssertEqual(2, keys.orderedInsertionIndex(for: CGPoint(x: 127, y: 60))) // D
        XCTAssertEqual(4, keys.orderedInsertionIndex(for: CGPoint(x: 128, y: 60))) // E

        XCTAssertEqual(5, keys.orderedInsertionIndex(for: CGPoint(x: 192, y: 60))) // F
        XCTAssertEqual(7, keys.orderedInsertionIndex(for: CGPoint(x: 256, y: 60))) // G
        XCTAssertEqual(9, keys.orderedInsertionIndex(for: CGPoint(x: 320, y: 60))) // A
        XCTAssertEqual(11, keys.orderedInsertionIndex(for: CGPoint(x: 384, y: 60))) // B

        XCTAssertEqual(9, keys.orderedInsertionIndex(for: CGPoint(x: 358, y: 60))) // A
        XCTAssertEqual(10, keys.orderedInsertionIndex(for: CGPoint(x: 358, y: 0))) // A#
        XCTAssertEqual(10, keys.orderedInsertionIndex(for: CGPoint(x: 409, y: 0))) // A#

        XCTAssertEqual(12, keys.orderedInsertionIndex(for: CGPoint(x: 7 * 64, y: 0)))
    }

    func testKeyCollectionKey() {
        let keys = makeKeys()
        XCTAssertNil(keys.key(for: CGPoint(x: -0.0001, y: 0.0)))
        XCTAssertEqual("C1", keys.key(for: CGPoint(x: 37, y: 0))?.note.label)
        XCTAssertEqual("C1", keys.key(for: CGPoint(x: 37, y: 60))?.note.label)
        XCTAssertEqual("C1", keys.key(for: CGPoint(x: 38, y: 60))?.note.label)
        XCTAssertEqual("C1", keys.key(for: CGPoint(x: 63.9, y: 60))?.note.label)

        XCTAssertEqual("C" + Note.sharpTag + "1", keys.key(for: CGPoint(x: 38, y: 59))?.note.label)
        XCTAssertEqual("C" + Note.sharpTag + "1", keys.key(for: CGPoint(x: 89, y: 59))?.note.label)

        XCTAssertEqual("D1", keys.key(for: CGPoint(x: 90, y: 0))?.note.label)
        XCTAssertEqual("D1", keys.key(for: CGPoint(x: 64 * 1, y: 60))?.note.label)
        XCTAssertEqual("D1", keys.key(for: CGPoint(x: 64 * 2 - 1, y: 60))?.note.label)
        XCTAssertEqual("E1", keys.key(for: CGPoint(x: 64 * 2, y: 60))?.note.label)
        XCTAssertEqual("E1", keys.key(for: CGPoint(x: 64 * 3 - 1, y: 0))?.note.label)
        XCTAssertEqual("F1", keys.key(for: CGPoint(x: 64 * 3, y: 0))?.note.label)
        XCTAssertEqual("F1", keys.key(for: CGPoint(x: 64 * 4 - 1, y: 60))?.note.label)
        XCTAssertEqual("F" + Note.sharpTag + "1", keys.key(for: CGPoint(x: 64.0 * 4 - 1, y: 0))?.note.label)
        XCTAssertEqual("G1", keys.key(for: CGPoint(x: 64 * 4, y: 60))?.note.label)
        XCTAssertEqual("G1", keys.key(for: CGPoint(x: 64 * 5 - 1, y: 60))?.note.label)
        XCTAssertEqual("G" + Note.sharpTag + "1", keys.key(for: CGPoint(x: 64 * 5, y: 0))?.note.label)
        XCTAssertEqual("A1", keys.key(for: CGPoint(x: 64 * 5, y: 60))?.note.label)
        XCTAssertEqual("A1", keys.key(for: CGPoint(x: 64 * 6 - 1, y: 60))?.note.label)
        XCTAssertEqual("A" + Note.sharpTag + "1", keys.key(for: CGPoint(x: 64 * 6, y: 0))?.note.label)
        XCTAssertEqual("B1", keys.key(for: CGPoint(x: 64 * 6, y: 60))?.note.label)
        XCTAssertNil(keys.key(for: CGPoint(x: 64.0 * 10, y: 0)))
    }

    func testKeyCollectionKeySpan() {
        let keys = makeKeys()

        let span1 = keys.keySpan(for: CGRect.zero)
        XCTAssertEqual(1, span1.count)
        XCTAssertEqual("C1", span1.first?.note.label)

        let span2 = keys.keySpan(for: CGRect(x: 32.0, y: 0.0, width: 64.0, height: 1.0))
        XCTAssertEqual(3, span2.count)
        XCTAssertEqual("C1", span2.first?.note.label)
        XCTAssertEqual("D1", span2.last?.note.label)

        let span3 = keys.keySpan(for: CGRect(x: 64 * 10, y: 0.0, width: 64.0, height: 1.0))
        XCTAssertEqual(0, span3.count)

        let span4 = keys.keySpan(for: CGRect(x: 64 * 7 - 1, y: 0.0, width: 64.0, height: 1.0))
        XCTAssertEqual(1, span4.count)
        XCTAssertEqual("B1", span4.last?.note.label)
    }
//    func testPerformanceExample() {
//        self.measure {
//        }
//    }
}
