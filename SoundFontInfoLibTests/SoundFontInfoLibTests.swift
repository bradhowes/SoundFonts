// Copyright © 2019 Brad Howes. All rights reserved.

import XCTest
import SoundFontInfoLib

class SoundFontInfoLibTests: XCTestCase {

    lazy var soundFont1: Data = {
        let bundle = Bundle(for: type(of: self))
        let url = bundle.url(forResource: "FluidR3_GM", withExtension: "sf2")!
        return try! Data(contentsOf: url)
    }()

    lazy var soundFont2: Data = {
        let bundle = Bundle(for: type(of: self))
        let url = bundle.url(forResource: "FreeFont", withExtension: "sf2")!
        return try! Data(contentsOf: url)
    }()

    lazy var soundFont3: Data = {
        let bundle = Bundle(for: type(of: self))
        let url = bundle.url(forResource: "GeneralUser GS MuseScore v1.442", withExtension: "sf2")!
        return try! Data(contentsOf: url)
    }()

    lazy var soundFont4: Data = {
        let bundle = Bundle(for: type(of: self))
        let url = bundle.url(forResource: "RolandNicePiano", withExtension: "sf2")!
        return try! Data(contentsOf: url)
    }()

    lazy var soundFonts: [Data] = {
        return [soundFont1, soundFont2, soundFont3, soundFont4]
    }()

    func testParsing1() {
        let sfi = soundFont1.withUnsafeBytes { SoundFontParse($0.baseAddress, $0.count)! }

        XCTAssertEqual(String(cString: SoundFontName(sfi)), "Fluid R3 GM")
        XCTAssertEqual(SoundFontPatchCount(sfi), 189)

        XCTAssertEqual(String(cString: SoundFontPatchName(sfi, 0)!), "Yamaha Grand Piano")
        XCTAssertEqual(SoundFontPatchBank(sfi, 0), 0)
        XCTAssertEqual(SoundFontPatchPatch(sfi, 0), 0)

        let lastPatchIndex = SoundFontPatchCount(sfi) - 1
        XCTAssertEqual(String(cString: SoundFontPatchName(sfi, lastPatchIndex)), "Orchestra Kit")
        XCTAssertEqual(SoundFontPatchBank(sfi, lastPatchIndex), 128)
        XCTAssertEqual(SoundFontPatchPatch(sfi, lastPatchIndex), 48)
    }

    func testParsing2() {
        let sfi = soundFont2.withUnsafeBytes { SoundFontParse($0.baseAddress, $0.count)! }

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

    func testParsing3() {
        let sfi = soundFont3.withUnsafeBytes { SoundFontParse($0.baseAddress, $0.count)! }

        XCTAssertEqual(String(cString: SoundFontName(sfi)), "GeneralUser GS MuseScore version 1.442")
        XCTAssertEqual(SoundFontPatchCount(sfi), 270)

        XCTAssertEqual(String(cString: SoundFontPatchName(sfi, 0)!), "Stereo Grand")
        XCTAssertEqual(SoundFontPatchBank(sfi, 0), 0)
        XCTAssertEqual(SoundFontPatchPatch(sfi, 0), 0)

        let lastPatchIndex = SoundFontPatchCount(sfi) - 1
        XCTAssertEqual(String(cString: SoundFontPatchName(sfi, lastPatchIndex)), "SFX")
        XCTAssertEqual(SoundFontPatchBank(sfi, lastPatchIndex), 128)
        XCTAssertEqual(SoundFontPatchPatch(sfi, lastPatchIndex), 56)
    }

    func testParsing4() {
        let sfi = soundFont4.withUnsafeBytes { SoundFontParse($0.baseAddress, $0.count)! }

        XCTAssertEqual(String(cString: SoundFontName(sfi)), "User Bank")
        XCTAssertEqual(SoundFontPatchCount(sfi), 1)

        XCTAssertEqual(String(cString: SoundFontPatchName(sfi, 0)!), "Nice Piano")
        XCTAssertEqual(SoundFontPatchBank(sfi, 0), 0)
        XCTAssertEqual(SoundFontPatchPatch(sfi, 0), 1)

        let lastPatchIndex = SoundFontPatchCount(sfi) - 1
        XCTAssertEqual(String(cString: SoundFontPatchName(sfi, lastPatchIndex)), "Nice Piano")
        XCTAssertEqual(SoundFontPatchBank(sfi, lastPatchIndex), 0)
        XCTAssertEqual(SoundFontPatchPatch(sfi, lastPatchIndex), 1)
    }

    func testDumps() {
        for sf in soundFonts {
            let sfi = sf.withUnsafeBytes { SoundFontParse($0.baseAddress, $0.count)! }
            let name = String(cString: SoundFontName(sfi)).replacingOccurrences(of: " ", with: "_")
            SoundFontDump(sfi, "/tmp/\(name)_dump.txt")
        }
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
        let original = soundFont1
        for _ in 0..<500 {
            let truncatedCount = Int.random(in: 1..<original.count);
            let data = original.subdata(in: 0..<truncatedCount)
            let sfi = data.withUnsafeBytes { SoundFontParse($0.baseAddress, $0.count) }
            XCTAssertNil(sfi)
        }
    }
}
