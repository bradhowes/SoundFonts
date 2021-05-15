// Copyright © 2021 Brad Howes. All rights reserved.

import Foundation

/**
 A tag is just a unique name that can be associated with zero or more sound fonts. By default there is an 'all' tag
 which matches all sound fonts.
 */
public final class LegacyTag: Codable {

    /// Type of the unique key associated with a tag
    public typealias Key = UUID

    /// The 'all' tag to which all sound fonts belong
    public static let allTag = LegacyTag()

    /// A set containing the 'all' tag. This is a convenience for combining another tag with the 'all' tag.
    public static let allTagSet = Set([allTag.key])

    /// The unique key for the tag.
    public let key: Key

    /// The name of the tag. Unlike the key, the name can be changed.
    public var name: String

    /// Constructor for the 'all' tag.
    private init() {
        let uuid: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                   UInt8, UInt8) =
            (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16)
        key = UUID(uuid: uuid)
        name = Formatters.strings.allTagName
        NotificationCenter.default.addObserver(forName: NSLocale.currentLocaleDidChangeNotification, object: nil,
                                               queue: nil) { _ in self.name = Formatters.strings.allTagName }
    }

    public init(name: String) {
        self.key = Key()
        self.name = name
    }
}

extension LegacyTag: Equatable {
    public static func == (lhs: LegacyTag, rhs: LegacyTag) -> Bool { lhs.key == rhs.key }
}

extension LegacyTag: CustomStringConvertible {
    public var description: String { "Tag('\(name)')" }
}
