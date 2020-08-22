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
        let sfi = soundFont1.withUnsafeBytes { SoundFontInfo.parse($0.baseAddress, size: $0.count)! }

        XCTAssertEqual(sfi.embeddedName, "Fluid R3 GM")
        XCTAssertEqual(sfi.patches.count, 189)

        XCTAssertEqual(sfi.patches[0].name, "Yamaha Grand Piano")
        XCTAssertEqual(sfi.patches[0].bank, 0)
        XCTAssertEqual(sfi.patches[0].patch, 0)

        let lastPatchIndex = sfi.patches.count - 1
        XCTAssertEqual(sfi.patches[lastPatchIndex].name, "Orchestra Kit")
        XCTAssertEqual(sfi.patches[lastPatchIndex].bank, 128)
        XCTAssertEqual(sfi.patches[lastPatchIndex].patch, 48)
    }

    func testParsing2() {
        let sfi = soundFont2.withUnsafeBytes { SoundFontInfo.parse($0.baseAddress, size: $0.count)! }

        XCTAssertEqual(sfi.embeddedName, "Free Font GM Ver. 3.2")
        XCTAssertEqual(sfi.patches.count, 235)

        XCTAssertEqual(sfi.patches[0].name, "Piano 1")
        XCTAssertEqual(sfi.patches[0].bank, 0)
        XCTAssertEqual(sfi.patches[0].patch, 0)

        let lastPatchIndex = sfi.patches.count - 1
        XCTAssertEqual(sfi.patches[lastPatchIndex].name, "SFX")
        XCTAssertEqual(sfi.patches[lastPatchIndex].bank, 128)
        XCTAssertEqual(sfi.patches[lastPatchIndex].patch, 56)
    }

    func testParsing3() {
        let sfi = soundFont3.withUnsafeBytes { SoundFontInfo.parse($0.baseAddress, size: $0.count)! }

        XCTAssertEqual(sfi.embeddedName, "GeneralUser GS MuseScore version 1.442")
        XCTAssertEqual(sfi.patches.count, 270)

        XCTAssertEqual(sfi.patches[0].name, "Stereo Grand")
        XCTAssertEqual(sfi.patches[0].bank, 0)
        XCTAssertEqual(sfi.patches[0].patch, 0)

        let lastPatchIndex = sfi.patches.count - 1
        XCTAssertEqual(sfi.patches[lastPatchIndex].name, "SFX")
        XCTAssertEqual(sfi.patches[lastPatchIndex].bank, 128)
        XCTAssertEqual(sfi.patches[lastPatchIndex].patch, 56)
    }

    func testParsing4() {
        let sfi = soundFont4.withUnsafeBytes { SoundFontInfo.parse($0.baseAddress, size: $0.count)! }

        XCTAssertEqual(sfi.embeddedName, "User Bank")
        XCTAssertEqual(sfi.patches.count, 1)

        XCTAssertEqual(sfi.patches[0].name, "Nice Piano")
        XCTAssertEqual(sfi.patches[0].bank, 0)
        XCTAssertEqual(sfi.patches[0].patch, 1)
    }

    func testDumps() {
        for sf in soundFonts {
            let sfi = sf.withUnsafeBytes { SoundFontInfo.parse($0.baseAddress, size: $0.count)! }
            let name = sfi.embeddedName.replacingOccurrences(of: " ", with: "_")
            sfi.dump("/tmp/\(name)_dump.txt")
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
        let sfi = data.withUnsafeBytes { SoundFontInfo.parse($0.baseAddress, size: $0.count) }
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
            let sfi = data.withUnsafeBytes { SoundFontInfo.parse($0.baseAddress, size: $0.count) }
            XCTAssertNil(sfi)
        }
    }
}
