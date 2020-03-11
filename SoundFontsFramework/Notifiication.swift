// Copyright © 2020 Brad Howes. All rights reserved.

import UIKit

extension Notification {

    /// Notification to check if now is a good time to ask for a review of the app
    static let askForReview = Notification(name: Notification.Name(rawValue: "askForReview"))

    /// Notification that the `showKeyLabels` setting changed
    static let showKeyLabelsChanged = Notification(name: Notification.Name(rawValue: "showKeyLabelsChanged"))

    /// Notification to visit the app store to review the app
    static let visitAppStore = Notification(name: Notification.Name(rawValue: "visitAppStore"))
}
