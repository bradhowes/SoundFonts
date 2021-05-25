// Copyright © 2020 Brad Howes. All rights reserved.

import XCTest
@testable import SoundFontsFramework

class FormattersTests: XCTestCase {

    func testStrings() {
        switch Locale.current.languageCode {
        case "en":
            XCTAssertEqual("Delete the soundfont file?", Formatters.strings.deleteFontTitle)
            XCTAssertEqual("Deleting will remove the file and also any favorites linked to it.", Formatters.strings.deleteFontMessage)
            XCTAssertEqual("Delete", Formatters.strings.deleteAction)
            XCTAssertEqual("Cancel", Formatters.strings.cancelAction)
        case "es":
            XCTAssertEqual("Delete the soundfont file?", Formatters.strings.deleteFontTitle)
            XCTAssertEqual("Deleting will remove the file and also any favorites linked to it.", Formatters.strings.deleteFontMessage)
            XCTAssertEqual("Delete", Formatters.strings.deleteAction)
            XCTAssertEqual("Cancel", Formatters.strings.cancelAction)
        case "fr":
            XCTAssertEqual("Delete the soundfont file?", Formatters.strings.deleteFontTitle)
            XCTAssertEqual("Deleting will remove the file and also any favorites linked to it.", Formatters.strings.deleteFontMessage)
            XCTAssertEqual("Delete", Formatters.strings.deleteAction)
            XCTAssertEqual("Cancel", Formatters.strings.cancelAction)
        case "de":
            XCTAssertEqual("Delete the soundfont file?", Formatters.strings.deleteFontTitle)
            XCTAssertEqual("Deleting will remove the file and also any favorites linked to it.", Formatters.strings.deleteFontMessage)
            XCTAssertEqual("Delete", Formatters.strings.deleteAction)
            XCTAssertEqual("Cancel", Formatters.strings.cancelAction)
        default: XCTFail("unexpected language code: \(Locale.current.languageCode ?? "?")")
        }
    }

    func testFiles() {
        switch Locale.current.languageCode {
        case "en":
            XCTAssertEqual("no files", Formatters.format(fileCount: 0))
            XCTAssertEqual("1 file", Formatters.format(fileCount: 1))
            XCTAssertEqual("200 files", Formatters.format(fileCount: 200))
        case "es":
            XCTAssertEqual("no files", Formatters.format(fileCount: 0))
            XCTAssertEqual("1 file", Formatters.format(fileCount: 1))
            XCTAssertEqual("200 files", Formatters.format(fileCount: 200))
        case "fr":
            XCTAssertEqual("no files", Formatters.format(fileCount: 0))
            XCTAssertEqual("1 file", Formatters.format(fileCount: 1))
            XCTAssertEqual("200 files", Formatters.format(fileCount: 200))
        case "de":
            XCTAssertEqual("keine Voreinstellungen", Formatters.format(fileCount: 0))
            XCTAssertEqual("1 Voreinstellung", Formatters.format(fileCount: 1))
            XCTAssertEqual("200 Voreinstellungen", Formatters.format(fileCount: 200))
        default: XCTFail("unexpected language code: \(Locale.current.languageCode ?? "?")")
        }
    }

    func testPatches() {
        switch Locale.current.languageCode {
        case "en":
            XCTAssertEqual("no presets", Formatters.format(presetCount: 0))
            XCTAssertEqual("1 preset", Formatters.format(presetCount: 1))
            XCTAssertEqual("200 presets", Formatters.format(presetCount: 200))
        case "es":
            XCTAssertEqual("no presets", Formatters.format(presetCount: 0))
            XCTAssertEqual("1 preset", Formatters.format(presetCount: 1))
            XCTAssertEqual("200 presets", Formatters.format(presetCount: 200))
        case "fr":
            XCTAssertEqual("no presets", Formatters.format(presetCount: 0))
            XCTAssertEqual("1 preset", Formatters.format(presetCount: 1))
            XCTAssertEqual("200 presets", Formatters.format(presetCount: 200))
        case "de":
            XCTAssertEqual("keine Voreinstellungen", Formatters.format(presetCount: 0))
            XCTAssertEqual("1 Voreinstellung", Formatters.format(presetCount: 1))
            XCTAssertEqual("200 Voreinstellungen", Formatters.format(presetCount: 200))
        default: XCTFail("unexpected language code: \(Locale.current.languageCode ?? "?")")
        }
    }

    func testFavorites() {
        switch Locale.current.languageCode {
        case "en":
            XCTAssertEqual("no favorites", Formatters.format(favoriteCount: 0))
            XCTAssertEqual("1 favorite", Formatters.format(favoriteCount: 1))
            XCTAssertEqual("200 favorites", Formatters.format(favoriteCount: 200))
        case "es":
            XCTAssertEqual("no favorites", Formatters.format(favoriteCount: 0))
            XCTAssertEqual("1 favorite", Formatters.format(favoriteCount: 1))
            XCTAssertEqual("200 favorites", Formatters.format(favoriteCount: 200))
        case "fr":
            XCTAssertEqual("no favorites", Formatters.format(favoriteCount: 0))
            XCTAssertEqual("1 favorite", Formatters.format(favoriteCount: 1))
            XCTAssertEqual("200 favorites", Formatters.format(favoriteCount: 200))
        case "de":
            XCTAssertEqual("no favorites", Formatters.format(favoriteCount: 0))
            XCTAssertEqual("1 favorite", Formatters.format(favoriteCount: 1))
            XCTAssertEqual("200 favorites", Formatters.format(favoriteCount: 200))
        default: XCTFail("unexpected language code: \(Locale.current.languageCode ?? "?")")
        }
    }

    func testEmptyFileCount() {
        switch Locale.current.languageCode {
        case "en":
            XCTAssertEqual("no empty files", Formatters.format(emptyFileCount: 0))
            XCTAssertEqual("1 empty file", Formatters.format(emptyFileCount: 1))
            XCTAssertEqual("2 empty files", Formatters.format(emptyFileCount: 2))
        case "es":
            XCTAssertEqual("no empty files", Formatters.format(emptyFileCount: 0))
            XCTAssertEqual("1 empty file", Formatters.format(emptyFileCount: 1))
            XCTAssertEqual("2 empty files", Formatters.format(emptyFileCount: 2))
        case "fr":
            XCTAssertEqual("no empty files", Formatters.format(emptyFileCount: 0))
            XCTAssertEqual("1 empty file", Formatters.format(emptyFileCount: 1))
            XCTAssertEqual("2 empty files", Formatters.format(emptyFileCount: 2))
        case "de":
            XCTAssertEqual("no empty files", Formatters.format(emptyFileCount: 0))
            XCTAssertEqual("1 empty file", Formatters.format(emptyFileCount: 1))
            XCTAssertEqual("2 empty files", Formatters.format(emptyFileCount: 2))
        default: XCTFail("unexpected language code: \(Locale.current.languageCode ?? "?")")
        }
    }

    func testInvalidFileCount() {
        switch Locale.current.languageCode {
        case "en":
            XCTAssertEqual("no invalid files", Formatters.format(invalidFileCount: 0))
            XCTAssertEqual("1 invalid file", Formatters.format(invalidFileCount: 1))
            XCTAssertEqual("2 invalid files", Formatters.format(invalidFileCount: 2))
        case "es":
            XCTAssertEqual("no invalid files", Formatters.format(invalidFileCount: 0))
            XCTAssertEqual("1 invalid file", Formatters.format(invalidFileCount: 1))
            XCTAssertEqual("2 invalid files", Formatters.format(invalidFileCount: 2))
        case "fr":
            XCTAssertEqual("no invalid files", Formatters.format(invalidFileCount: 0))
            XCTAssertEqual("1 invalid file", Formatters.format(invalidFileCount: 1))
            XCTAssertEqual("2 invalid files", Formatters.format(invalidFileCount: 2))
        case "de":
            XCTAssertEqual("no invalid files", Formatters.format(invalidFileCount: 0))
            XCTAssertEqual("1 invalid file", Formatters.format(invalidFileCount: 1))
            XCTAssertEqual("2 invalid files", Formatters.format(invalidFileCount: 2))
        default: XCTFail("unexpected language code: \(Locale.current.languageCode ?? "?")")
        }
    }

    func testFailedToAddFileCount() {
        switch Locale.current.languageCode {
        case "en":
            XCTAssertEqual("no failed to install", Formatters.format(failedToAddFileCount: 0))
            XCTAssertEqual("1 failed to install", Formatters.format(failedToAddFileCount: 1))
            XCTAssertEqual("2 failed to install", Formatters.format(failedToAddFileCount: 2))
        case "es":
            XCTAssertEqual("no failed to install", Formatters.format(failedToAddFileCount: 0))
            XCTAssertEqual("1 failed to install", Formatters.format(failedToAddFileCount: 1))
            XCTAssertEqual("2 failed to install", Formatters.format(failedToAddFileCount: 2))
        case "fr":
            XCTAssertEqual("no failed to install", Formatters.format(failedToAddFileCount: 0))
            XCTAssertEqual("1 failed to install", Formatters.format(failedToAddFileCount: 1))
            XCTAssertEqual("2 failed to install", Formatters.format(failedToAddFileCount: 2))
        case "de":
            XCTAssertEqual("no failed to install", Formatters.format(failedToAddFileCount: 0))
            XCTAssertEqual("1 failed to install", Formatters.format(failedToAddFileCount: 1))
            XCTAssertEqual("2 failed to install", Formatters.format(failedToAddFileCount: 2))
        default: XCTFail("unexpected language code: \(Locale.current.languageCode ?? "?")")
        }
    }

    func testAddSoundFontFailureText() {
        switch Locale.current.languageCode {
        case "en":
            XCTAssertEqual("", Formatters.makeAddSoundFontFailureText(failures: []))
            XCTAssertEqual("1 empty file (one)",
                           Formatters.makeAddSoundFontFailureText(failures: [.emptyFile("one")]))
            XCTAssertEqual("2 empty files (one, two)",
                           Formatters.makeAddSoundFontFailureText(failures: [.emptyFile("one"),
                                                                             .emptyFile("two")]))
            XCTAssertEqual("1 invalid file (two), 2 empty files (one, three)",
                           Formatters.makeAddSoundFontFailureText(failures: [.emptyFile("one"),
                                                                             .invalidFile("two"),
                                                                             .emptyFile("three")]))
            XCTAssertEqual("1 invalid file (two), 2 failed to install (four, six), 3 empty files (one, three, five)",
                           Formatters.makeAddSoundFontFailureText(failures: [.emptyFile("one"),
                                                                             .invalidFile("two"),
                                                                             .emptyFile("three"),
                                                                             .unableToCreateFile("four"),
                                                                             .emptyFile("five"),
                                                                             .unableToCreateFile("six")]))
        case "fr":
            XCTAssertEqual("", Formatters.makeAddSoundFontFailureText(failures: []))
            XCTAssertEqual("1 empty file (one)",
                           Formatters.makeAddSoundFontFailureText(failures: [.emptyFile("one")]))
            XCTAssertEqual("2 empty files (one, two)",
                           Formatters.makeAddSoundFontFailureText(failures: [.emptyFile("one"),
                                                                             .emptyFile("two")]))
            XCTAssertEqual("1 invalid file (two), 2 empty files (one, three)",
                           Formatters.makeAddSoundFontFailureText(failures: [.emptyFile("one"),
                                                                             .invalidFile("two"),
                                                                             .emptyFile("three")]))
            XCTAssertEqual("1 invalid file (two), 2 failed to install (four, six), 3 empty files (one, three, five)",
                           Formatters.makeAddSoundFontFailureText(failures: [.emptyFile("one"),
                                                                             .invalidFile("two"),
                                                                             .emptyFile("three"),
                                                                             .unableToCreateFile("four"),
                                                                             .emptyFile("five"),
                                                                             .unableToCreateFile("six")]))
        case "es":
            XCTAssertEqual("", Formatters.makeAddSoundFontFailureText(failures: []))
            XCTAssertEqual("1 empty file (one)",
                           Formatters.makeAddSoundFontFailureText(failures: [.emptyFile("one")]))
            XCTAssertEqual("2 empty files (one, two)",
                           Formatters.makeAddSoundFontFailureText(failures: [.emptyFile("one"),
                                                                             .emptyFile("two")]))
            XCTAssertEqual("1 invalid file (two), 2 empty files (one, three)",
                           Formatters.makeAddSoundFontFailureText(failures: [.emptyFile("one"),
                                                                             .invalidFile("two"),
                                                                             .emptyFile("three")]))
            XCTAssertEqual("1 invalid file (two), 2 failed to install (four, six), 3 empty files (one, three, five)",
                           Formatters.makeAddSoundFontFailureText(failures: [.emptyFile("one"),
                                                                             .invalidFile("two"),
                                                                             .emptyFile("three"),
                                                                             .unableToCreateFile("four"),
                                                                             .emptyFile("five"),
                                                                             .unableToCreateFile("six")]))
        default: XCTFail("unexpeted language code: \(Locale.current.languageCode ?? "?")")
        }
    }

    func testAddSoundFontDoneMessage() {
        XCTAssertEqual("Unable to add any sound fonts.",
                       Formatters.makeAddSoundFontBody(ok: [], failures: [], total: 0))
        XCTAssertEqual("Unable to add the sound font: 1 empty file (one)",
                       Formatters.makeAddSoundFontBody(ok: [], failures: [.emptyFile("one")], total: 1))
        XCTAssertEqual("Added 1 out of 2 sound fonts: 1 invalid file (one)",
                       Formatters.makeAddSoundFontBody(ok: ["two"], failures: [.invalidFile("one")], total: 2))
        XCTAssertEqual("Added all of the sound fonts.",
                       Formatters.makeAddSoundFontBody(ok: ["one", "two"], failures: [], total: 2))
        XCTAssertEqual("Added the sound font.",
                       Formatters.makeAddSoundFontBody(ok: ["one"], failures: [], total: 1))
    }

    func testFormatSliderValue() {
        XCTAssertEqual("0.000", Formatters.format(sliderValue: 0.0))
        XCTAssertEqual("0.123", Formatters.format(sliderValue: 0.1234))
        XCTAssertEqual("0.124", Formatters.format(sliderValue: 0.1236))
        XCTAssertEqual("9.193", Formatters.format(sliderValue: 99.193))
        XCTAssertEqual("-0.123", Formatters.format(sliderValue: -0.1234))
        XCTAssertEqual("-0.124", Formatters.format(sliderValue: -0.1236))
        XCTAssertEqual("-9.193", Formatters.format(sliderValue: -99.193))
    }
}
