// Copyright © 2019 Brad Howes. All rights reserved.

import XCTest
@testable import SoundFonts

class SoundFontListTests: XCTestCase {

    func testParsing() {
        let bundle = Bundle.main
        let sft = bundle.url(forResource: "FluidR3_GM", withExtension: "sf2")!
        let data = try! Data.init(contentsOf: sft)
        let contents = GetSoundFontInfo(data: data)
        XCTAssertFalse(contents.patches.isEmpty)
        XCTAssertEqual(contents.patches.count, 123)

        let firstPatch = contents.patches[0]
        XCTAssertEqual(firstPatch.name, "")
        XCTAssertEqual(firstPatch.bank, 0)
        XCTAssertEqual(firstPatch.patch, 1)

        let lastPatch = contents.patches[contents.patches.count - 1]
        XCTAssertEqual(lastPatch.name, "")
        XCTAssertEqual(lastPatch.bank, 0)
        XCTAssertEqual(lastPatch.patch, 1)
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
        let bundle = Bundle.main
        let sft = bundle.url(forResource: "FluidR3_GM", withExtension: "sf2")!
        let original = try! Data(contentsOf: sft)
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
