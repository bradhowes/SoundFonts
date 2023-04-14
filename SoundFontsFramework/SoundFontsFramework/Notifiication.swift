// Copyright © 2020 Brad Howes. All rights reserved.

import UIKit

extension Notification.Name {
  /// Notification to visit the app store to review the app
  public static let visitAppStore = Notification.Name(rawValue: "visitAppStore")
  /// Notification about synth failure.
  public static let synthStartFailure = Notification.Name("synthStartFailure")
  /// Notification to show the changes screen
  public static let showChanges = Notification.Name("showChanges")
  /// Notification to show the tutorial screen
  public static let showTutorial = Notification.Name("showTutorial")
  /// Notification that app is resigning active state
  public static let appResigningActive = Notification.Name("appResigningActive")

  /// Notification to check if now is a good time to ask for a review of the app
  static let askForReview = Notification.Name(rawValue: "askForReview")
  /// Notification that the `showKeyLabels` setting changed
  static let keyLabelOptionChanged = Notification.Name(rawValue: "keyLabelOptionChanged")
  /// Notification that the key width changed
  static let keyWidthChanged = Notification.Name(rawValue: "keyWidthChanged")
  /// Notification that we found some orphan files
  static let soundFontsCollectionOrphans = Notification.Name("soundFontsCollectionOrphans")
  /// Notification that we cannot read/use an SF2 file
  static let soundFontFileAccessDenied = Notification.Name("soundFontFileAccessDenied")
  /// Notification that we cannot locate an SF2 file
  static let soundFontFileNotAvailable = Notification.Name("soundFontFileNotAvailable")
  /// Notification that the active preset config changed.
  static let activePresetConfigChanged = Notification.Name("activePresetConfigChanged")
  /// Notification that the synth tuning should changed
  static let tuningChanged = Notification.Name("tuningChanged")
  /// Notification that the synth gain should changed
  static let gainChanged = Notification.Name("gainChanged")
  /// Notification that the synth pan should changed
  static let panChanged = Notification.Name("panChanged")
  /// Notification that the synth pitch-bend range should changed
  static let pitchBendRangeChanged = Notification.Name("pitchBendRangeChanged")
  /// Failed to load the consolidated config file
  static let configLoadFailure = Notification.Name("configLoadFailure")
  /// Notification that the effects view is appearing.
  static let showingEffects = Notification.Name("showingEffects")
  /// Notification that the effects view is going away.
  static let hidingEffects = Notification.Name("hidingEffects")
  /// Notification of MIDI activity on a given channel
  static let midiActivity = Notification.Name("midiActivity")
  /// Notification of MIDI activity on a given channel
  static let midiAction = Notification.Name("midiAction")
  /// Notification that a preset is loading
  static let presetLoading = Notification.Name("presetLoading")
  /// Notification that active reverb config has changed
  static let reverbConfigChanged = Notification.Name("reverbConfigChanged")
  /// Notification that active delay config has changed
  static let delayConfigChanged = Notification.Name("delayConfigChanged")
  /// Notification that a Bookmark has changed
  static let bookmarkChanged = Notification.Name("bookmarkChanged")
}
