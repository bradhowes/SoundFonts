// Copyright © 2020 Brad Howes. All rights reserved.

import UIKit

extension Notification.Name {
  /// Notification to check if now is a good time to ask for a review of the app
  public static let askForReview = Notification.Name(rawValue: "askForReview")
  /// Notification that the `showKeyLabels` setting changed
  public static let keyLabelOptionChanged = Notification.Name(rawValue: "keyLabelOptionChanged")
  /// Notification to visit the app store to review the app
  public static let visitAppStore = Notification.Name(rawValue: "visitAppStore")
  /// Notification that the key width changed
  public static let keyWidthChanged = Notification.Name(rawValue: "keyWidthChanged")
  /// Notification that we found some orphan files
  public static let soundFontsCollectionOrphans = Notification.Name("soundFontsCollectionOrphans")
  /// Notification that we cannot read/use an SF2 file
  public static let soundFontFileAccessDenied = Notification.Name("soundFontFileAccessDenied")
  /// Notification that we cannot locate an SF2 file
  public static let soundFontFileNotAvailable = Notification.Name("soundFontFileNotAvailable")
  /// Notification that the active preset config changed.
  public static let activePresetConfigChanged = Notification.Name("activePresetConfigChanged")
  /// Notification that the sampler tuning should changed
  public static let tuningChanged = Notification.Name("tuningChanged")
  /// Notification that the sampler gain should changed
  public static let gainChanged = Notification.Name("gainChanged")
  /// Notification that the sampler pan should changed
  public static let panChanged = Notification.Name("panChanged")
  /// Notification that the sampler pitch-bend range should changed
  public static let pitchBendRangeChanged = Notification.Name("pitchBendRangeChanged")
  /// Failed to load the consolidated config file
  public static let configLoadFailure = Notification.Name("configLoadFailure")
  /// Notification that the effects view is appearing.
  public static let showingEffects = Notification.Name("showingEffects")
  /// Notification that the effects view is going away.
  public static let hidingEffects = Notification.Name("hidingEffects")
  /// Notification about sampler failure.
  public static let samplerStartFailure = Notification.Name("samplerStartFailure")
  /// Notification that app is resigning active state
  public static let appResigningActive = Notification.Name("appResigningActive")
  /// Notification to show the tutorial screen
  public static let showTutorial = Notification.Name("showTutorial")
  /// Notification that the tags view is appearing.
  public static let showingTags = Notification.Name("showingTags")
}
