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

    /// Notification that we failed to load the SoundFontCollection.plist file
    public static let soundFontsCollectionLoadFailure = Notification.Name("soundFontsCollectionLoadFailure")

    /// Notification that we failed to load the Tags.plist file
    public static let tagsCollectionLoadFailure = Notification.Name("tagsCollectionLoadFailure")

    /// Notification that we found some orphan files
    public static let soundFontsCollectionOrphans = Notification.Name("soundFontsCollectionOrphans")

    /// Notification that we failed to load the Favorites.plist file
    public static let favoritesCollectionLoadFailure = Notification.Name("favoritesCollectionLoadFailure")

    /// Notification that we cannot read/use an SF2 file
    public static let soundFontFileAccessDenied = Notification.Name("soundFontFileAccessDenied")

    /// Notification that we cannot locate an SF2 file
    public static let soundFontFileNotAvailable = Notification.Name("soundFontFileNotAvailable")

    /// A PresetConfig changed
    public static let presetConfigChanged = Notification.Name("presetConfigChanged")

    /// Set a tuning
    public static let setTuning = Notification.Name("setTuningChanged")
}
