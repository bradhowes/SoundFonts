// Copyright © 2019 Brad Howes. All rights reserved.

import XCTest
import SoundFontInfoLib
import SF2Files

class SoundFontInfoLibTests: XCTestCase {

    let names = ["FluidR3_GM", "FreeFont", "GeneralUser GS MuseScore v1.442", "RolandNicePiano"]
    let urls: [URL] = SF2Files.allResources.sorted { $0.lastPathComponent < $1.lastPathComponent }

    func testParsing1() {
        let sfi = SoundFontInfo.load(urls[0])!

        XCTAssertEqual(sfi.embeddedName, "Fluid R3 GM")
        XCTAssertEqual(sfi.presets.count, 189)

        XCTAssertEqual(sfi.presets[0].name, "Yamaha Grand Piano")
        XCTAssertEqual(sfi.presets[0].bank, 0)
        XCTAssertEqual(sfi.presets[0].preset, 0)

        let lastPatchIndex = sfi.presets.count - 1
        XCTAssertEqual(sfi.presets[lastPatchIndex].name, "Orchestra Kit")
        XCTAssertEqual(sfi.presets[lastPatchIndex].bank, 128)
        XCTAssertEqual(sfi.presets[lastPatchIndex].preset, 48)
    }

    func testParsing2() {
        let sfi = SoundFontInfo.load(urls[1])!

        XCTAssertEqual(sfi.embeddedName, "Free Font GM Ver. 3.2")
        XCTAssertEqual(sfi.presets.count, 235)

        XCTAssertEqual(sfi.presets[0].name, "Piano 1")
        XCTAssertEqual(sfi.presets[0].bank, 0)
        XCTAssertEqual(sfi.presets[0].preset, 0)

        let lastPatchIndex = sfi.presets.count - 1
        XCTAssertEqual(sfi.presets[lastPatchIndex].name, "SFX")
        XCTAssertEqual(sfi.presets[lastPatchIndex].bank, 128)
        XCTAssertEqual(sfi.presets[lastPatchIndex].preset, 56)
    }

    func testParsing3() {
        let sfi = SoundFontInfo.load(urls[2])!

        XCTAssertEqual(sfi.embeddedName, "GeneralUser GS MuseScore version 1.442")
        XCTAssertEqual(sfi.presets.count, 270)

        XCTAssertEqual(sfi.presets[0].name, "Stereo Grand")
        XCTAssertEqual(sfi.presets[0].bank, 0)
        XCTAssertEqual(sfi.presets[0].preset, 0)

        let lastPatchIndex = sfi.presets.count - 1
        XCTAssertEqual(sfi.presets[lastPatchIndex].name, "SFX")
        XCTAssertEqual(sfi.presets[lastPatchIndex].bank, 128)
        XCTAssertEqual(sfi.presets[lastPatchIndex].preset, 56)
    }

    func testParsing4() {
        let sfi = SoundFontInfo.load(urls[3])!

        XCTAssertEqual(sfi.embeddedName, "User Bank")
        XCTAssertEqual(sfi.presets.count, 1)

        XCTAssertEqual(sfi.presets[0].name, "Nice Piano")
        XCTAssertEqual(sfi.presets[0].bank, 0)
        XCTAssertEqual(sfi.presets[0].preset, 1)
    }

    func testDumps() {
        for sf in urls {
            let sfi = SoundFontInfo.load(sf)!
            let name = sfi.embeddedName.replacingOccurrences(of: " ", with: "_")
            sfi.dump("/tmp/\(name)_dump.txt")
        }
    }

    var newTempFileURL: URL {
        URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent(UUID().uuidString)
    }

    /**
     Generate file with random contents and try to process them to make sure that there are no BAD_ACCESS
     exceptions.
     */
    func testRobustnessWithRandomPayload() {
        let tmp = newTempFileURL
        defer { try? FileManager.default.removeItem(at: tmp) }

        let size = 2048
        var data = Data(count: size)
        _ = data.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, size, $0.baseAddress!) }
        try! data.write(to: tmp, options: .atomic)
        let sfi = SoundFontInfo.load(tmp)
        XCTAssertNil(sfi)
    }

    /**
     Generate partial soundfont file contents and try to process them to make sure that there are no BAD_ACCESS
     exceptions.
     */
    func testRobustnessWIthPartialPayload() {
        let tmp = newTempFileURL
        defer { try? FileManager.default.removeItem(at: tmp) }

        let original = try! Data(contentsOf: urls[0])
        for _ in 0..<100 {
            let truncatedCount = Int.random(in: 1..<(original.count / 2));
            let data = original.subdata(in: 0..<truncatedCount)
            try! data.write(to: tmp, options: .atomic)
            let sfi = SoundFontInfo.load(tmp)
            XCTAssertNil(sfi)
        }
    }
}
