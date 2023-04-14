// Copyright © 2019 Brad Howes. All rights reserved.

import UIKit

private class BundleTag {}

/// Collection of value formatters that use localized strings.
struct Formatters {

  struct Strings {
    private var bundle: Bundle { Bundle(for: BundleTag.self) }

    var allTagName: String {
      NSLocalizedString("allTagName", bundle: bundle, comment: "The name of the 'all' tag.")
    }

    var builtInTagName: String {
      NSLocalizedString(
        "builtInTagName", bundle: bundle, comment: "The name of the 'Built-in' tag.")
    }

    var newTagName: String {
      NSLocalizedString(
        "newTagName", bundle: bundle, comment: "The initial name to use for a new tag")
    }

    var cancelButton: String {
      NSLocalizedString("cancelButton", bundle: bundle, comment: "Cancel or dismiss view")
    }

    var editButton: String {
      NSLocalizedString("editButton", bundle: bundle, comment: "Begin editing")
    }

    var doneButton: String {
      NSLocalizedString("doneButton", bundle: bundle, comment: "End editing")
    }

    var saveButton: String {
      NSLocalizedString("saveButton", bundle: bundle, comment: "Save current values")
    }

    var volumeIsZero: String {
      NSLocalizedString("volumeIsZero", bundle: bundle, comment: "HUD message when volume is 0")
    }

    var noPresetLoaded: String {
      NSLocalizedString(
        "noPresetLoaded", bundle: bundle, comment: "HUD message when no preset is loaded")
    }

    var otherAppAudio: String {
      NSLocalizedString(
        "otherAppAudio", bundle: bundle, comment: "HUD message when another app controls audio")
    }

    var configLoadFailureAlert: (String, String) {
      (
        NSLocalizedString(
          "configLoadFailureTitle", bundle: bundle,
          comment: "Alert title when config file fails to load"),
        NSLocalizedString(
          "configLoadFailureBody", bundle: bundle,
          comment: "Alert message when config file fails to load")
      )
    }

    var soundFontsCollectionOrphansAlert: (String, String) {
      (
        NSLocalizedString(
          "soundFontsCollectionOrphansAlert", bundle: bundle,
          comment: "Alert title when there are SF2 orphan files"),
        NSLocalizedString(
          "soundFontsCollectionOrphansBody", bundle: bundle,
          comment: "Alert message when there are SF2 orphan files")
      )
    }

    var soundFontFileAccessDeniedAlert: (String, String) {
      (
        NSLocalizedString(
          "soundFontFileAccessDeniedTitle", bundle: bundle,
          comment: "Alert title when denied access to SF2 file"),
        NSLocalizedString(
          "soundFontFileAccessDeniedBody", bundle: bundle,
          comment: "Alert message when denied access to SF2 file")
      )
    }

    var synthStartFailureTitle: String {
      NSLocalizedString(
        "synthStartFailureTitle", bundle: bundle,
        comment: "Alert title when there is a sampler start failure")
    }

    var noSynthFailureBody: String {
      NSLocalizedString(
        "noSamplerFailureBody", bundle: bundle,
        comment: "Alert message when there is no sampler available to start")
    }

    var engineStartingFailureBody: String {
      NSLocalizedString(
        "engineStartingFailureBody", bundle: bundle,
        comment: "Alert message when there is starting audio engine fails")
    }

    var patchLoadingFailureBody: String {
      NSLocalizedString(
        "patchLoadingFailureBody", bundle: bundle,
        comment: "Alert message when loading a preset fails")
    }

    var sessionActivatingFailureBody: String {
      NSLocalizedString(
        "sessionActivatingFailureBody", bundle: bundle,
        comment: "Alert message when audio session activating fails")
    }

    var fileCount: String {
      NSLocalizedString(
        "fileCount", bundle: bundle,
        comment: "failed add count string format in Localized.stringsdict")
    }

    var presetCount: String {
      NSLocalizedString(
        "presetCount", bundle: bundle,
        comment: "presets count string format in Localized.stringsdict")
    }

    var favoriteCount: String {
      NSLocalizedString(
        "favoriteCount", bundle: bundle,
        comment: "favorites count string format in Localized.stringsdict")
    }

    var emptyFileCount: String {
      NSLocalizedString("emptyFileCount", bundle: bundle, comment: "empty file")
    }

    var invalidFileCount: String {
      NSLocalizedString("invalidFileCount", bundle: bundle, comment: "invalid file")
    }

    var failedToAddFileCount: String {
      NSLocalizedString("failedToAddFileCount", bundle: bundle, comment: "no space for file")
    }

    var deleteFontTitle: String {
      NSLocalizedString("deleteFontTitle", bundle: bundle, comment: "Title of confirmation prompt")
    }

    var deleteFontMessage: String {
      NSLocalizedString(
        "deleteFontBody", bundle: bundle,
        comment: "Body of confirmation prompt")
    }
    var deleteAction: String {
      NSLocalizedString("deleteAction", bundle: bundle, comment: "The delete action")
    }

    var cancelAction: String {
      NSLocalizedString("cancelAction", bundle: bundle, comment: "The cancel action")
    }

    var addSoundFontsStatusTitle: String {
      NSLocalizedString(
        "addSoundFontsStatusTitle", bundle: bundle,
        comment: "Title of alert showing results when adding sound fonts")
    }

    var unableToAddOneFile: String {
      NSLocalizedString(
        "unableToAddOneFile", bundle: bundle,
        comment: "Unable to add the sound font.")
    }
    var unableToAddAnyFiles: String {
      NSLocalizedString(
        "unableToAddAnyFiles", bundle: bundle,
        comment: "Unable to add any sound fonts.")
    }
    var addedOneFile: String {
      NSLocalizedString(
        "addedOneFile", bundle: bundle,
        comment: "Added the sound font.")
    }
    var addedAllFiles: String {
      NSLocalizedString(
        "addedAllFiles", bundle: bundle,
        comment: "Added all of the sound fonts.")
    }
    var addedSomeFiles: String {
      NSLocalizedString(
        "addedSomeFiles", bundle: bundle,
        comment: "Added %d out of %d sound fonts.")
    }

    var hidePresetTitle: String {
      NSLocalizedString(
        "hidePresetTitle", bundle: bundle, comment: "Title of hide preset confirmation prompt")
    }

    var hidePresetMessage: String {
      NSLocalizedString(
        "hidePresetBody", bundle: bundle,
        comment: "Body of hide preset confirmation prompt")
    }
    var hidePresetAction: String {
      NSLocalizedString(
        "hidePresetAction", bundle: bundle,
        comment: "The hide preset confirmation action")
    }
  }

  static let strings: Strings = Strings()

  /**
   Obtain a formatted slider value.

   - parameter sliderValue the value to format
   - returns string value
   */
  static func format(sliderValue: Float) -> String {
    sliderFormatter.string(for: sliderValue) ?? "???"
  }
  /**
   Obtain a formatted representation of a file count

   - parameter fileCount: value to format
   - returns: string value
   */
  static func format(fileCount: Int) -> String {
    .localizedStringWithFormat(strings.fileCount, fileCount)
  }

  /**
   Obtain a formatted representation of a preset count value.

   - parameter presetCount: value to format
   - returns: string value
   */
  static func format(presetCount: Int) -> String {
    .localizedStringWithFormat(strings.presetCount, presetCount)
  }

  static func format(favoriteCount: Int) -> String {
    .localizedStringWithFormat(strings.favoriteCount, favoriteCount)
  }

  static func format(emptyFileCount: Int) -> String {
    .localizedStringWithFormat(strings.emptyFileCount, emptyFileCount)
  }

  static func format(invalidFileCount: Int) -> String {
    .localizedStringWithFormat(strings.invalidFileCount, invalidFileCount)
  }

  static func format(failedToAddFileCount: Int) -> String {
    .localizedStringWithFormat(strings.failedToAddFileCount, failedToAddFileCount)
  }

  /**
   Generate a string that shows what failed when attempting to add one or more sound fonts to the app.

   - parameter failures: the list of failures
   - returns: string value
   */
  static func makeAddSoundFontFailureText(failures: [SoundFontFileLoadFailure]) -> String {
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
    case .emptyFile: return format(emptyFileCount: count)
    case .invalidFile: return format(invalidFileCount: count)
    case .unableToCreateFile: return format(failedToAddFileCount: count)
    }
  }

  /**
   Generate a string that shows the success and failures when adding one or more sound fonts to the app.

   - parameter ok: the names of the sound fonts that succeeded
   - parameter failures: the collection of failures and their reasons
   - parameter total: total number of sound fonts attempted
   - returns: string value
   */
  static func makeAddSoundFontBody(
    ok: [String], failures: [SoundFontFileLoadFailure],
    total: Int
  ) -> String {
    let message: String = {
      switch (ok.count, failures.count) {
      case (0, 1): return strings.unableToAddOneFile
      case (0, _): return strings.unableToAddAnyFiles
      case (1, 0): return strings.addedOneFile
      case (_, 0): return strings.addedAllFiles
      case (_, _): return String.localizedStringWithFormat(strings.addedSomeFiles, ok.count, total)
      }
    }()
    let reasons = makeAddSoundFontFailureText(failures: failures)
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

}
