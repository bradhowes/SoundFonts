//
//  SoundFontListTests.swift
//  SoundFontsTests
//
//  Created by Brad Howes on 11/21/19.
//  Copyright © 2019 Brad Howes. All rights reserved.
//

import XCTest
import SoundFonts

class SoundFontListTests: XCTestCase {

    func testParsing() {
        let bundle = Bundle(for: SoundFont.self)
        let sft = bundle.url(forResource: "FluidR3_GM", withExtension: "sf2")!
        let data = try! Data.init(contentsOf: sft)
        let contents = SoundFontPatchList(data: data)
        XCTAssertFalse(contents.isEmpty)

        let soundFont = SoundFont.library["Fluid R3 GM"]!
        XCTAssertEqual(contents.count, soundFont.patches.count)

        let firstPatch = contents[0]
        XCTAssertEqual(firstPatch.name, soundFont.patches[0].name)
        XCTAssertEqual(firstPatch.bank, soundFont.patches[0].bank)
        XCTAssertEqual(firstPatch.patch, soundFont.patches[0].patch)

        let lastPatch = contents[contents.count - 1]
        XCTAssertEqual(lastPatch.name, soundFont.patches.last!.name)
        XCTAssertEqual(lastPatch.bank, soundFont.patches.last!.bank)
        XCTAssertEqual(lastPatch.patch, soundFont.patches.last!.patch)
    }

    /**
     Generate file with random contents and try to process them to make sure that there are no BAD_ACCESS
     exceptions.
     */

    func testRobustnessWithRandomPayload() {
        let size = 2048
        var data = Data(count: size)
        _ = data.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, size, $0.baseAddress!) }
        let contents = SoundFontPatchList(data: data)
        XCTAssertTrue(contents.isEmpty)
    }

    /**
     Generate partial soundfont file contents and try to process them to make sure that there are no BAD_ACCESS
     exceptions.
     */
    func testRobustnessWIthPartialPayload() {
        let bundle = Bundle(for: SoundFont.self)
        let sft = bundle.url(forResource: "FluidR3_GM", withExtension: "sf2")!
        let original = try! Data(contentsOf: sft)
        for _ in 0..<500 {
            let truncatedCount = Int.random(in: 1 ... original.count);
            let data = original.subdata(in: 0..<truncatedCount)
            let contents = SoundFontPatchList(data: data)
            XCTAssertTrue(contents.isEmpty)
        }
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
