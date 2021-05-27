// Copyright © 2020 Brad Howes. All rights reserved.

import XCTest
import SoundFontInfoLib
import CoreData

@testable import SoundFontsFramework

class PlistTranslationTests: XCTestCase {

    func testSoundFontLibraryLoading() {

//        let oldSoundFonts: LegacySoundFontCollection = {
//            let bundle = Bundle(for: type(of: self))
//            let url = bundle.url(forResource: "SoundFontLibrary", withExtension: "plist")!
//            let data = try! Data(contentsOf: url)
//            return try! PropertyListDecoder().decode(LegacySoundFontCollection.self, from: data)
//        }()
//
//        let oldFavorites: LegacyFavoriteCollection = {
//            let bundle = Bundle(for: type(of: self))
//            let url = bundle.url(forResource: "Favorites", withExtension: "plist")!
//            let data = try! Data(contentsOf: url)
//            return try! PropertyListDecoder().decode(LegacyFavoriteCollection.self, from: data)
//        }()
//
//        doWhenCoreDataReady(#function) { cdth, context in
//            let app = ManagedAppState.get(context: context)
//
//            var lookup = [UUID:ManagedSoundFont]()
//            for soundFont in oldSoundFonts.soundFonts {
//                let sf = SoundFont(in: context, import: soundFont)
//                XCTAssertEqual(soundFont.key, sf.uuid)
//                lookup[sf.uuid] = sf
//            }
//
//            XCTAssertEqual(ManagedSoundFont.countRows(in: context), 9)
//            let soundFonts = ManagedSoundFont.fetchRows(in: context)
//            XCTAssertEqual(soundFonts.count, 9)
//
//            for soundFont in soundFonts {
//                guard let source = oldSoundFonts.getBy(key: soundFont.uuid) else { fatalError() }
//                XCTAssertEqual(source.displayName, soundFont.name)
//                XCTAssertEqual(source.embeddedName, soundFont.embeddedName)
//                XCTAssertEqual(source.fileURL, soundFont.path)
//                XCTAssertEqual(source.removable, !soundFont.resource)
//
//                for (index, preset) in soundFont.presets.enumerated() {
//                    let patch = source.patches[index]
//                    XCTAssertEqual(patch.originalName, preset.displayName)
//                    XCTAssertEqual(patch.bank, Int(preset.bank))
//                    XCTAssertEqual(patch.program, Int(preset.patch))
//                    XCTAssertEqual(patch.soundFontIndex, index)
//                }
//            }
//
//            var favorites = [ManagedFavorite]()
//            for index in 0..<oldFavorites.count {
//                let oldFave = oldFavorites.getBy(index: index)
//                let soundFontKey = oldFave.soundFontAndPatch.soundFontKey
//                let patchIndex = oldFave.soundFontAndPatch.patchIndex
//                if let sf = lookup[soundFontKey] {
//                    let fave = app.createFavorite(preset: sf.presets[patchIndex],
//                                                  keyboardLowestNote: oldFave.presetConfig.keyboardLowestNote?.midiNoteValue ?? 0)
//                    fave.setName(oldFave.presetConfig.name)
//                    fave.setPan(oldFave.presetConfig.pan)
//                    fave.setGain(oldFave.presetConfig.gain)
//                    favorites.append(fave)
//                }
//            }
//
//            let f0 = favorites[0]
//            XCTAssertEqual(f0.displayName, "Synclavier")
//            XCTAssertEqual(f0.keyboardLowestNote, 48)
//            XCTAssertEqual(f0.pan, -1.0)
//            XCTAssertEqual(f0.gain, 0.0)

//            XCTAssertEqual(f0.preset.displayName, "Evil Synclavier")
//            XCTAssertEqual(f0.preset.parent.name, "Evil synclavier")
//        }
    }
}
