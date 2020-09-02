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

    public static let soundFontsCollectionLoadFailure = Notification.Name("soundFontsCollectionLoadFailure")

    public static let favoritesCollectionLoadFailure = Notification.Name("favoritesCollectionLoadFailure")
}
