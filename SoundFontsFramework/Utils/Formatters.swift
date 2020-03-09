// Copyright © 2019 Brad Howes. All rights reserved.

import UIKit

public enum Formatters {

    /**
     Obtain a formatted string that shows the number of patches in a SoundFont

     - parameter patchCount: the count value to format
     - returns: the formatted result
     */
    public static func formatted(patchCount: Int) -> String {
        String.localizedStringWithFormat(Self.patchesFormatString, patchCount)
    }

    /**
     Obtain a formatted string that shows the number of favorites.

     - parameter favoriteCount: the count value to format
     - returns: the formatted result
     */
    public static func formatted(favoriteCount: Int) -> String {
        String.localizedStringWithFormat(Self.favoritesFormatString, favoriteCount)
    }
}

private extension Formatters {

    /// Obtain the localized format string for patch counts
    static let patchesFormatString = "patches count"
        .localized(comment: "patches count string format in Localized.stringsdict")

    /// Obtain the localized format string for favorite counts
    static let favoritesFormatString = "favorites count"
        .localized(comment: "favorites count string format in Localized.stringsdict")
}
