// Copyright © 2019 Brad Howes. All rights reserved.

import XCTest
import SoundFontInfoLib

class SFFileTests: XCTestCase {

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

    func testInit() {
        for sf in soundFonts {
            let _ = sf.withUnsafeBytes { SoundFontInfo.parse($0.baseAddress, size:$0.count)! }
        }
    }
}
