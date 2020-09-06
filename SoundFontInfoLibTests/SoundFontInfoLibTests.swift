// Copyright © 2019 Brad Howes. All rights reserved.

import XCTest
import SoundFontInfoLib

class SoundFontInfoLibTests: XCTestCase {

    lazy var testBundle = Bundle(for: type(of: self))

    let names = ["FluidR3_GM", "FreeFont", "GeneralUser GS MuseScore v1.442", "RolandNicePiano"]
    lazy var urls: [URL] = names.map { testBundle.url(forResource: $0, withExtension: "sf2")! }

//    var resources: [URL] {
//        let testBundle = Bundle(for: type(of: self))
//        return testBundle.urls(forResourcesWithExtension: "sf2", subdirectory: nil, localization: nil)!
//    }

    func testParsing1() {
        let sfi = SoundFontInfo.load(urls[0])!

        XCTAssertEqual(sfi.embeddedName, "Fluid R3 GM")
        XCTAssertEqual(sfi.patches.count, 189)

        XCTAssertEqual(sfi.patches[0].name, "Yamaha Grand Piano")
        XCTAssertEqual(sfi.patches[0].bank, 0)
        XCTAssertEqual(sfi.patches[0].preset, 0)

        let lastPatchIndex = sfi.patches.count - 1
        XCTAssertEqual(sfi.patches[lastPatchIndex].name, "Orchestra Kit")
        XCTAssertEqual(sfi.patches[lastPatchIndex].bank, 128)
        XCTAssertEqual(sfi.patches[lastPatchIndex].preset, 48)
    }

    func testParsing2() {
        let sfi = SoundFontInfo.load(urls[1])!

        XCTAssertEqual(sfi.embeddedName, "Free Font GM Ver. 3.2")
        XCTAssertEqual(sfi.patches.count, 235)

        XCTAssertEqual(sfi.patches[0].name, "Piano 1")
        XCTAssertEqual(sfi.patches[0].bank, 0)
        XCTAssertEqual(sfi.patches[0].preset, 0)

        let lastPatchIndex = sfi.patches.count - 1
        XCTAssertEqual(sfi.patches[lastPatchIndex].name, "SFX")
        XCTAssertEqual(sfi.patches[lastPatchIndex].bank, 128)
        XCTAssertEqual(sfi.patches[lastPatchIndex].preset, 56)
    }

    func testParsing3() {
        let sfi = SoundFontInfo.load(urls[2])!

        XCTAssertEqual(sfi.embeddedName, "GeneralUser GS MuseScore version 1.442")
        XCTAssertEqual(sfi.patches.count, 270)

        XCTAssertEqual(sfi.patches[0].name, "Stereo Grand")
        XCTAssertEqual(sfi.patches[0].bank, 0)
        XCTAssertEqual(sfi.patches[0].preset, 0)

        let lastPatchIndex = sfi.patches.count - 1
        XCTAssertEqual(sfi.patches[lastPatchIndex].name, "SFX")
        XCTAssertEqual(sfi.patches[lastPatchIndex].bank, 128)
        XCTAssertEqual(sfi.patches[lastPatchIndex].preset, 56)
    }

    func testParsing4() {
        let sfi = SoundFontInfo.load(urls[3])!

        XCTAssertEqual(sfi.embeddedName, "User Bank")
        XCTAssertEqual(sfi.patches.count, 1)

        XCTAssertEqual(sfi.patches[0].name, "Nice Piano")
        XCTAssertEqual(sfi.patches[0].bank, 0)
        XCTAssertEqual(sfi.patches[0].preset, 1)
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
