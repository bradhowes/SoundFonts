// Copyright © 2019 Brad Howes. All rights reserved.

import UIKit

enum Formatters {

    static func formatted(patchCount: Int) -> String {
        String.localizedStringWithFormat(Self.patchesFormatString, patchCount)
    }

    static func formatted(favoriteCount: Int) -> String {
        String.localizedStringWithFormat(Self.favoritesFormatString, favoriteCount)
    }
}

private extension Formatters {

    static let patchesFormatString = NSLocalizedString(
        "patches count", comment: "patches count string format in Localized.stringsdict")

    static let favoritesFormatString = NSLocalizedString(
        "favorites count", comment: "favorites count string format in Localized.stringsdict")
}
