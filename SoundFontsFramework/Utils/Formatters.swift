// Copyright © 2019 Brad Howes. All rights reserved.

import UIKit

private class Tag {}

public enum Formatters {

    public static func formatted(patchCount: Int) -> String { .localizedStringWithFormat(Self.patchesFormatString, patchCount) }
    public static func formatted(favoriteCount: Int) -> String { .localizedStringWithFormat(Self.favoritesFormatString, favoriteCount) }
    public static func formatted(failedAddCount: Int, condition: String) -> String {
        let value = String.localizedStringWithFormat(Self.failedAddCountString, failedAddCount)
        return String(format: value, condition.localized(comment: "add soundfont failure condition"))
    }

    public static func addSoundFontFailureText(failures: [SoundFontFileLoadFailure]) -> String {
        guard !failures.isEmpty else { return "" }
        var counts = [SoundFontFileLoadFailure: [String]]()
        for failure in failures {
            var files = counts[failure] ?? []
            files.append(failure.file)
            counts[failure] = files
        }

        let strings: [String] = counts.compactMap { (key: SoundFontFileLoadFailure, files: [String]) -> String in
            let statement: String = {
                switch key {
                case .emptyFile: return Formatters.formatted(failedAddCount: files.count, condition: "empty".localized(comment: "empty file"))
                case .invalidSoundFont: return Formatters.formatted(failedAddCount: files.count, condition: "invalid".localized(comment: "invalid file"))
                case .unableToCreateFile: return Formatters.formatted(failedAddCount: files.count, condition: "uncopyable".localized(comment: "no space for file"))
                }
            }() + " (" + files.joined(separator: ", ") + ")"
            return statement
        }
        return strings.sorted().joined(separator: ", ")
    }

    public static func addSoundFontDoneMessage(ok: [String], failures: [SoundFontFileLoadFailure], total: Int) -> String {
        let message: String = {
            switch (ok.count, failures.count) {
            case (0, 1): return "UnableToAddOneFile".localized(comment: "unable to add one file")
            case (0, _): return "UnableToAddAnyFiles".localized(comment: "unable to add any files")
            case (1, 0): return "AddedOneFile".localized(comment: "added one file")
            case (_, 0): return "AddedAllFiles".localized(comment: "added all files")
            case (_, _): return String.localizedStringWithFormat("AddedSomeFiles".localized(comment: "added some files"), ok.count, total)
            }
        }()
        let reasons = addSoundFontFailureText(failures: failures)
        return reasons.isEmpty ? (message + ".") : (message + ": " + reasons)
    }

    private static var sliderFormatter: Formatter = {
        let formatter = NumberFormatter()
        formatter.allowsFloats = true
        formatter.alwaysShowsDecimalSeparator = true
        formatter.formatterBehavior = .default
        formatter.roundingMode = .halfEven
        formatter.maximumFractionDigits = 3
        formatter.minimumFractionDigits = 3
        formatter.minimumIntegerDigits = 1
        formatter.maximumIntegerDigits = 1
        return formatter
    }()

    public static func formatted(sliderValue: Float) -> String { sliderFormatter.string(for: sliderValue) ?? "???" }
}

private extension Formatters {
    static let bundle = Bundle(identifier: "com.braysoftware.SoundFontsFramework")!
    static let patchesFormatString = "patches count".localized(comment: "patches count string format in Localized.stringsdict")
    static let favoritesFormatString = "favorites count".localized(comment: "favorites count string format in Localized.stringsdict")
    static let failedAddCountString = "failed add count".localized(comment: "failed add count string format in Localized.stringsdict")
}
