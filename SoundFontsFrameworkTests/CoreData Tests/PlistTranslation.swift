// Copyright © 2020 Brad Howes. All rights reserved.

import XCTest
import SoundFontInfoLib
import CoreData

@testable import SoundFontsFramework

class PlistTranslationTests: XCTestCase {

    func testSoundFontLibraryLoadiing() {

        let oldSoundFonts: LegacySoundFontCollection = {
            let bundle = Bundle(for: type(of: self))
            let url = bundle.url(forResource: "SoundFontLibrary", withExtension: "plist")!
            let data = try! Data(contentsOf: url)
            return try! PropertyListDecoder().decode(LegacySoundFontCollection.self, from: data)
        }()

        let oldFavorites: LegacyFavoriteCollection = {
            let bundle = Bundle(for: type(of: self))
            let url = bundle.url(forResource: "Favorites", withExtension: "plist")!
            let data = try! Data(contentsOf: url)
            return try! PropertyListDecoder().decode(LegacyFavoriteCollection.self, from: data)
        }()

        doWhenCoreDataReady(#function) { cdth, context in
            let app = AppState.get(context: context)

            var lookup = [UUID:SoundFont]()
            for soundFont in oldSoundFonts.soundFonts {
                let sf = SoundFont(in: context, import: soundFont)
                XCTAssertEqual(soundFont.key, sf.uuid)
                lookup[sf.uuid] = sf
            }

            XCTAssertEqual(SoundFont.countRows(in: context), 9)
            let soundFonts = SoundFont.fetchRows(in: context)
            XCTAssertEqual(soundFonts.count, 9)

            for soundFont in soundFonts {
                guard let source = oldSoundFonts.getBy(key: soundFont.uuid) else { fatalError() }
                XCTAssertEqual(source.displayName, soundFont.name)
                XCTAssertEqual(source.embeddedName, soundFont.embeddedName)
                XCTAssertEqual(source.fileURL, soundFont.path)
                XCTAssertEqual(source.removable, !soundFont.resource)

                for (index, preset) in soundFont.presets.enumerated() {
                    let patch = source.patches[index]
                    XCTAssertEqual(patch.name, preset.name)
                    XCTAssertEqual(patch.bank, Int(preset.bank))
                    XCTAssertEqual(patch.program, Int(preset.preset))
                    XCTAssertEqual(patch.soundFontIndex, index)
                }
            }

            var favorites = [Favorite]()
            for index in 0..<oldFavorites.count {
                let oldFave = oldFavorites.getBy(index: index)
                let soundFontKey = oldFave.soundFontAndPatch.soundFontKey
                let patchIndex = oldFave.soundFontAndPatch.patchIndex
                if let sf = lookup[soundFontKey] {
                    let fave = app.createFavorite(preset: sf.presets[patchIndex],
                                                  keyboardLowestNote: oldFave.keyboardLowestNote?.midiNoteValue ?? 0)
                    fave.setName(oldFave.name)
                    fave.setPan(oldFave.pan)
                    fave.setGain(oldFave.gain)
                    favorites.append(fave)
                }
            }

            let f0 = favorites[0]
            XCTAssertEqual(f0.name, "Synclavier")
            XCTAssertEqual(f0.keyboardLowestNote, 48)
            XCTAssertEqual(f0.pan, -1.0)
            XCTAssertEqual(f0.gain, 0.0)

            XCTAssertEqual(f0.preset.name, "Evil Synclavier")
            XCTAssertEqual(f0.preset.parent.name, "Evil synclavier")
        }
    }
}
