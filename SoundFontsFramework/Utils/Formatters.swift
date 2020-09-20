// Copyright © 2019 Brad Howes. All rights reserved.

import UIKit

private class Tag {}

public enum Formatters {

    /**
     Obtain a formatted string that shows the number of patches in a SoundFont

     - parameter patchCount: the count value to format
     - returns: the formatted result
     */
    public static func formatted(patchCount: Int) -> String { .localizedStringWithFormat(Self.patchesFormatString, patchCount) }

    /**
     Obtain a formatted string that shows the number of favorites.

     - parameter favoriteCount: the count value to format
     - returns: the formatted result
     */
    public static func formatted(favoriteCount: Int) -> String { .localizedStringWithFormat(Self.favoritesFormatString, favoriteCount) }

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

    public static func formatted(sliderValue: Float) -> String { sliderFormatter.string(for: sliderValue) ?? "???" }
}

private extension Formatters {
    static let bundle = Bundle(identifier: "com.braysoftware.SoundFontsFramework")!

    /// Obtain the localized format string for patch counts
    static let patchesFormatString = localizedString("patches count", comment: "patches count string format in Localized.stringsdict")

    /// Obtain the localized format string for favorite counts
    static let favoritesFormatString = localizedString("favorites count", comment: "favorites count string format in Localized.stringsdict")

    private static func localizedString(_ title: String, comment: String) -> String {
        NSLocalizedString(title, tableName: nil, bundle: Self.bundle, value: "", comment: comment)
    }
}
