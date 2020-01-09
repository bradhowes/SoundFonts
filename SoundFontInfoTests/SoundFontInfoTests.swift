// Copyright © 2019 Brad Howes. All rights reserved.

import XCTest
import SoundFontsFramework

class SoundFontInfoTests: XCTestCase {

    private var soundFont: URL? {
        let bundle = Bundle(identifier: "com.braysoftware.SoundFontsFramework")
        return bundle?.urls(forResourcesWithExtension: "sf2", subdirectory: nil)?.first { $0.path.contains("FreeFont") }
    }

    func testParsing() {
        let data = try! Data.init(contentsOf: soundFont!)
        let contents = GetSoundFontInfo(data: data)
        XCTAssertFalse(contents.patches.isEmpty)
        XCTAssertEqual(contents.patches.count, 235)

        let firstPatch = contents.patches[0]
        XCTAssertEqual(firstPatch.name, "Piano 1")
        XCTAssertEqual(firstPatch.bank, 0)
        XCTAssertEqual(firstPatch.patch, 0)

        let lastPatch = contents.patches[contents.patches.count - 1]
        XCTAssertEqual(lastPatch.name, "SFX")
        XCTAssertEqual(lastPatch.bank, 128)
        XCTAssertEqual(lastPatch.patch, 56)
    }

    /**
     Generate file with random contents and try to process them to make sure that there are no BAD_ACCESS
     exceptions.
     */

    func testRobustnessWithRandomPayload() {
        let size = 2048
        var data = Data(count: size)
        _ = data.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, size, $0.baseAddress!) }
        let contents = GetSoundFontInfo(data: data)
        XCTAssertTrue(contents.name.isEmpty)
        XCTAssertTrue(contents.patches.isEmpty)
    }

    /**
     Generate partial soundfont file contents and try to process them to make sure that there are no BAD_ACCESS
     exceptions.
     */
    func testRobustnessWIthPartialPayload() {
        let original = try! Data(contentsOf: soundFont!)
        for _ in 0..<500 {
            let truncatedCount = Int.random(in: 1 ... original.count);
            let data = original.subdata(in: 0..<truncatedCount)
            let contents = GetSoundFontInfo(data: data)
            XCTAssertTrue(contents.name.isEmpty)
            XCTAssertTrue(contents.patches.isEmpty)
        }
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
