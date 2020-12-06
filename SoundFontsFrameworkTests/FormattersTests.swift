// Copyright © 2020 Brad Howes. All rights reserved.

import XCTest
@testable import SoundFontsFramework

class FormattersTests: XCTestCase {

    func testPatches() {
        switch Locale.current.languageCode {
        case "en":
            XCTAssertEqual("no presets", Formatters.formatted(presetCount: 0))
            XCTAssertEqual("1 preset", Formatters.formatted(presetCount: 1))
            XCTAssertEqual("200 presets", Formatters.formatted(presetCount: 200))
        case "es":
            XCTAssertEqual("no presets", Formatters.formatted(presetCount: 0))
            XCTAssertEqual("1 preset", Formatters.formatted(presetCount: 1))
            XCTAssertEqual("200 presets", Formatters.formatted(presetCount: 200))
        case "fr":
            XCTAssertEqual("pas des préréglés", Formatters.formatted(presetCount: 0))
            XCTAssertEqual("1 préréglé", Formatters.formatted(presetCount: 1))
            XCTAssertEqual("200 préréglés", Formatters.formatted(presetCount: 200))
        case "de":
            XCTAssertEqual("keine Voreinstellungen", Formatters.formatted(presetCount: 0))
            XCTAssertEqual("1 Voreinstellung", Formatters.formatted(presetCount: 1))
            XCTAssertEqual("200 Voreinstellungen", Formatters.formatted(presetCount: 200))
        default: XCTFail("unexpeted language code: \(Locale.current.languageCode ?? "?")")
        }
    }

    func testFavorites() {
        switch Locale.current.languageCode {
        case "en":
            XCTAssertEqual("no favorites", Formatters.formatted(favoriteCount: 0))
            XCTAssertEqual("1 favorite", Formatters.formatted(favoriteCount: 1))
            XCTAssertEqual("200 favorites", Formatters.formatted(favoriteCount: 200))
        case "es":
            XCTAssertEqual("no favorites", Formatters.formatted(favoriteCount: 0))
            XCTAssertEqual("1 favorite", Formatters.formatted(favoriteCount: 1))
            XCTAssertEqual("200 favorites", Formatters.formatted(favoriteCount: 200))
        case "fr":
            XCTAssertEqual("pas des préférés", Formatters.formatted(favoriteCount: 0))
            XCTAssertEqual("1 préféré", Formatters.formatted(favoriteCount: 1))
            XCTAssertEqual("200 préférés", Formatters.formatted(favoriteCount: 200))
        case "de":
            XCTAssertEqual("no favorites", Formatters.formatted(favoriteCount: 0))
            XCTAssertEqual("1 favorite", Formatters.formatted(favoriteCount: 1))
            XCTAssertEqual("200 favorites", Formatters.formatted(favoriteCount: 200))
        default: XCTFail("unexpeted language code: \(Locale.current.languageCode ?? "?")")
        }
    }

    func testFailedFileCount() {
        switch Locale.current.languageCode {
        case "en":
            XCTAssertEqual("no empty files", Formatters.formatted(failedAddCount: 0, condition: "empty"))
            XCTAssertEqual("1 empty file", Formatters.formatted(failedAddCount: 1, condition: "empty"))
            XCTAssertEqual("2 empty files", Formatters.formatted(failedAddCount: 2, condition: "empty"))
        case "es":
            XCTAssertEqual("no empty files", Formatters.formatted(failedAddCount: 0, condition: "empty"))
            XCTAssertEqual("1 empty file", Formatters.formatted(failedAddCount: 1, condition: "empty"))
            XCTAssertEqual("2 empty files", Formatters.formatted(failedAddCount: 2, condition: "empty"))
        case "fr":
            XCTAssertEqual("1 fichier vide", Formatters.formatted(failedAddCount: 1, condition: "empty"))
            XCTAssertEqual("2 ficiers vides", Formatters.formatted(failedAddCount: 2, condition: "empty"))
        case "de":
            XCTAssertEqual("no empty files", Formatters.formatted(failedAddCount: 0, condition: "empty"))
            XCTAssertEqual("1 empty file", Formatters.formatted(failedAddCount: 1, condition: "empty"))
            XCTAssertEqual("2 empty files", Formatters.formatted(failedAddCount: 2, condition: "empty"))
        default: XCTFail("unexpeted language code: \(Locale.current.languageCode ?? "?")")
        }
    }

    func testAddSoundFontFailureText() {
        switch Locale.current.languageCode {
        case "en":
            XCTAssertEqual("", Formatters.addSoundFontFailureText(failures: []))
            XCTAssertEqual("1 empty file (one)",
                           Formatters.addSoundFontFailureText(failures: [.emptyFile("one")]))
            XCTAssertEqual("2 empty files (one, two)",
                           Formatters.addSoundFontFailureText(failures: [.emptyFile("one"),
                                                                         .emptyFile("two")]))
            XCTAssertEqual("1 invalid file (two), 2 empty files (one, three)",
                           Formatters.addSoundFontFailureText(failures: [.emptyFile("one"),
                                                                         .invalidSoundFont("two"),
                                                                         .emptyFile("three")]))
            XCTAssertEqual("1 invalid file (two), 2 uncopyable files (four, six), 3 empty files (one, three, five)",
                           Formatters.addSoundFontFailureText(failures: [.emptyFile("one"),
                                                                         .invalidSoundFont("two"),
                                                                         .emptyFile("three"),
                                                                         .unableToCreateFile("four"),
                                                                         .emptyFile("five"),
                                                                         .unableToCreateFile("six")]))
        case "fr":
            XCTAssertEqual("", Formatters.addSoundFontFailureText(failures: []))
            XCTAssertEqual("1 empty file (one)",
                           Formatters.addSoundFontFailureText(failures: [.emptyFile("one")]))
            XCTAssertEqual("2 empty files (one, two)",
                           Formatters.addSoundFontFailureText(failures: [.emptyFile("one"),
                                                                         .emptyFile("two")]))
            XCTAssertEqual("1 invalid file (two), 2 empty files (one, three)",
                           Formatters.addSoundFontFailureText(failures: [.emptyFile("one"),
                                                                         .invalidSoundFont("two"),
                                                                         .emptyFile("three")]))
            XCTAssertEqual("1 invalid file (two), 2 uncopyable files (four, six), 3 empty files (one, three, five)",
                           Formatters.addSoundFontFailureText(failures: [.emptyFile("one"),
                                                                         .invalidSoundFont("two"),
                                                                         .emptyFile("three"),
                                                                         .unableToCreateFile("four"),
                                                                         .emptyFile("five"),
                                                                         .unableToCreateFile("six")]))
        case "es":
            XCTAssertEqual("", Formatters.addSoundFontFailureText(failures: []))
            XCTAssertEqual("1 empty file (one)",
                           Formatters.addSoundFontFailureText(failures: [.emptyFile("one")]))
            XCTAssertEqual("2 empty files (one, two)",
                           Formatters.addSoundFontFailureText(failures: [.emptyFile("one"),
                                                                         .emptyFile("two")]))
            XCTAssertEqual("1 invalid file (two), 2 empty files (one, three)",
                           Formatters.addSoundFontFailureText(failures: [.emptyFile("one"),
                                                                         .invalidSoundFont("two"),
                                                                         .emptyFile("three")]))
            XCTAssertEqual("1 invalid file (two), 2 uncopyable files (four, six), 3 empty files (one, three, five)",
                           Formatters.addSoundFontFailureText(failures: [.emptyFile("one"),
                                                                         .invalidSoundFont("two"),
                                                                         .emptyFile("three"),
                                                                         .unableToCreateFile("four"),
                                                                         .emptyFile("five"),
                                                                         .unableToCreateFile("six")]))
        default: XCTFail("unexpeted language code: \(Locale.current.languageCode ?? "?")")
        }
    }

    func testAddSoundFontDoneMessage() {
        XCTAssertEqual("Unable to add any sound fonts.", Formatters.addSoundFontDoneMessage(ok: [], failures: [], total: 0))
        XCTAssertEqual("Unable to add the sound font: 1 empty file (one)", Formatters.addSoundFontDoneMessage(ok: [], failures: [.emptyFile("one")], total: 1))
        XCTAssertEqual("Added 1 out of 2 sound fonts: 1 invalid file (one)", Formatters.addSoundFontDoneMessage(ok: ["two"], failures: [.invalidSoundFont("one")], total: 2))
        XCTAssertEqual("Added all of the sound fonts.", Formatters.addSoundFontDoneMessage(ok: ["one", "two"], failures: [], total: 2))
        XCTAssertEqual("Added the sound font.", Formatters.addSoundFontDoneMessage(ok: ["one"], failures: [], total: 1))
    }
}
