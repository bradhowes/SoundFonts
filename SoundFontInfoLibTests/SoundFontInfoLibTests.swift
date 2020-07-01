// Copyright © 2019 Brad Howes. All rights reserved.

import XCTest
import SoundFontInfoLib

class SoundFontInfoLibTests: XCTestCase {

    var soundFont: Data {
        let bundle = Bundle(for: type(of: self))
        let url = bundle.url(forResource: "FreeFont", withExtension: "sf2")!
        return try! Data(contentsOf: url)
    }

    func testParsing() {
        let sfi = soundFont.withUnsafeBytes { SoundFontParse($0.baseAddress, $0.count)! }

        XCTAssertEqual(String(cString: SoundFontName(sfi)), "Free Font GM Ver. 3.2")
        XCTAssertEqual(SoundFontPatchCount(sfi), 235)

        XCTAssertEqual(String(cString: SoundFontPatchName(sfi, 0)!), "Piano 1")
        XCTAssertEqual(SoundFontPatchBank(sfi, 0), 0)
        XCTAssertEqual(SoundFontPatchPatch(sfi, 0), 0)

        let lastPatchIndex = SoundFontPatchCount(sfi) - 1
        XCTAssertEqual(String(cString: SoundFontPatchName(sfi, lastPatchIndex)), "SFX")
        XCTAssertEqual(SoundFontPatchBank(sfi, lastPatchIndex), 128)
        XCTAssertEqual(SoundFontPatchPatch(sfi, lastPatchIndex), 56)
    }

    func testDump() {
        let sfi = soundFont.withUnsafeBytes { SoundFontParse($0.baseAddress, $0.count)! }
        SoundFontDump(sfi, "/tmp/SoundFontDump.txt");
    }

    /**
     Generate file with random contents and try to process them to make sure that there are no BAD_ACCESS
     exceptions.
     */
    func testRobustnessWithRandomPayload() {
        let size = 2048
        var data = Data(count: size)
        _ = data.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, size, $0.baseAddress!) }
        let sfi = data.withUnsafeBytes { SoundFontParse($0.baseAddress, $0.count) }
        XCTAssertNil(sfi)
    }

    /**
     Generate partial soundfont file contents and try to process them to make sure that there are no BAD_ACCESS
     exceptions.
     */
    func testRobustnessWIthPartialPayload() {
        let original = soundFont
        for _ in 0..<500 {
            let truncatedCount = Int.random(in: 1..<original.count);
            let data = original.subdata(in: 0..<truncatedCount)
            let sfi = data.withUnsafeBytes { SoundFontParse($0.baseAddress, $0.count) }
            XCTAssertNil(sfi)
        }
    }
}
