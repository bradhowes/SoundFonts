// Copyright © 2019 Brad Howes. All rights reserved.

import UIKit

private class BundleTag {}

/**
 Collection of value formatters. Original intent was to make consolidate string formatting here, but this is a mess and
 needs to be reworked.
 */
public struct Formatters {
    private static var bundle: Bundle { Bundle(for: BundleTag.self) }

    public static let emptyFile = NSLocalizedString("empty", bundle: bundle, comment: "empty file")
    public static let invalidFile = NSLocalizedString("invalid", bundle: bundle, comment: "invalid file")
    public static let failedFile = NSLocalizedString("failed", bundle: bundle, comment: "no space for file")
    public static let unableToAddOneFile = NSLocalizedString("UnableToAddOneFile", bundle: bundle,
                                                             comment: "unable to add one file")
    public static let unableToAddAnyFiles = NSLocalizedString("UnableToAddAnyFiles", bundle: bundle,
                                                              comment: "unable to add any files")
    public static let addedOneFile = NSLocalizedString("AddedOneFile", bundle: bundle, comment: "added one file")
    public static let addedAllFiles = NSLocalizedString("AddedAllFiles", bundle: bundle, comment: "added all files")
    public static let addedSomeFiles = NSLocalizedString("AddedSomeFiles", bundle: bundle, comment: "added some files")

    public static let deleteFontTitle = NSLocalizedString("DeleteFontTitle", bundle: bundle,
                                                          comment: "Title of confirmation prompt")
    public static let deleteFontMessage = NSLocalizedString("DeleteFontMessage", bundle: bundle,
                                                            comment: "Body of confirmation prompt")
    public static let deleteAction = NSLocalizedString("Delete", bundle: bundle, comment: "The delete action")
    public static let cancelAction = NSLocalizedString("Cancel", bundle: bundle, comment: "The cancel action")

    /**
     Obtain a formatted representation of a preset count value.

     - parameter presetCount: value to format
     - returns: string value
     */
    public static func formatted(presetCount: Int) -> String {
        .localizedStringWithFormat(Self.presetsFormatString, presetCount)
    }

    /**
     Obtain a formatted representation of a favorites count value.

     - parameter favoriteCount: value to format
     - returns: string value
     */
    public static func formatted(favoriteCount: Int) -> String {
        .localizedStringWithFormat(Self.favoritesFormatString, favoriteCount)
    }

    /**
     Obtain a formatted representation of a failed sound font add counter

     - parameter failedAddCount: value to format
     - parameter condition: what failure took place
     - returns: string value
     */
    public static func formatted(failedAddCount: Int, condition: String) -> String {
        let value = String.localizedStringWithFormat(Self.failedAddCountString, failedAddCount)
        return String(format: value, condition)
    }

    /**
     Generate a string that shows what failed when attempting to add one or more sound fonts to the app.

     - parameter failures: the list of failures
     - returns: string value
     */
    public static func addSoundFontFailureText(failures: [SoundFontFileLoadFailure]) -> String {
        guard !failures.isEmpty else { return "" }
        var counts = [SoundFontFileLoadFailure: [String]]()
        for failure in failures {
            var files = counts[failure] ?? []
            files.append(failure.file)
            counts[failure] = files
        }

        let strings: [String] = counts.compactMap { (key: SoundFontFileLoadFailure, files: [String]) -> String in
            "\(getLocalizedReason(key: key, count: files.count)) (\(files.joined(separator: ", ")))"
        }

        return strings.sorted().joined(separator: ", ")
    }

    private static func getLocalizedReason(key: SoundFontFileLoadFailure, count: Int) -> String {
        switch key {
        case .emptyFile: return formatted(failedAddCount: count, condition: emptyFile)
        case .invalidSoundFont: return formatted(failedAddCount: count, condition: invalidFile)
        case .unableToCreateFile: return formatted(failedAddCount: count, condition: failedFile)
        }
    }

    /**
     Generate a string that shows the success and failures when adding one or more sound fonts to the app.

     - parameter ok: the names of the sound fonts that succeeded
     - parameter failures: the collection of failures and their reasons
     - parameter total: total number of sound fonts attempted
     - returns: string value
     */
    public static func addSoundFontDoneMessage(ok: [String], failures: [SoundFontFileLoadFailure],
                                               total: Int) -> String {
        let message: String = {
            switch (ok.count, failures.count) {
            case (0, 1): return unableToAddOneFile
            case (0, _): return unableToAddAnyFiles
            case (1, 0): return addedOneFile
            case (_, 0): return addedAllFiles
            case (_, _): return String.localizedStringWithFormat(addedSomeFiles, ok.count, total)
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

    /**
     Obtain a formatted slider value.

     - parameter sliderValue the value to format
     - returns string value
     */
    public static func formatted(sliderValue: Float) -> String { sliderFormatter.string(for: sliderValue) ?? "???" }
}

private extension Formatters {
    static let presetsFormatString =
        NSLocalizedString("presets count", bundle: bundle,
                          comment: "presets count string format in Localized.stringsdict")
    static let favoritesFormatString =
        NSLocalizedString("favorites count", bundle: bundle,
                          comment: "favorites count string format in Localized.stringsdict")
    static let failedAddCountString =
        NSLocalizedString("failed add count", bundle: bundle,
                          comment: "failed add count string format in Localized.stringsdict")
}
