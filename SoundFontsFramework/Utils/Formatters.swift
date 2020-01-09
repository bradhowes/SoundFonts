// Copyright © 2019 Brad Howes. All rights reserved.

import UIKit

private class Tag {}

public enum Formatters {

    public static func formatted(patchCount: Int) -> String {
        String.localizedStringWithFormat(Self.patchesFormatString, patchCount)
    }

    public static func formatted(favoriteCount: Int) -> String {
        String.localizedStringWithFormat(Self.favoritesFormatString, favoriteCount)
    }
}

private extension Formatters {

    private static func localizedString(_ title: String, comment: String) -> String {
        return NSLocalizedString(title, bundle: Bundle(for: Tag.self), comment: comment)
    }


    static let patchesFormatString = localizedString(
        "patches count", comment: "patches count string format in Localized.stringsdict")

    static let favoritesFormatString = localizedString(
        "favorites count", comment: "favorites count string format in Localized.stringsdict")
}
