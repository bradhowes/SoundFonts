// Copyright © 2021 Brad Howes. All rights reserved.

import Foundation

/**
 A tag is just a unique name that can be associated with zero or more sound fonts. By default there is an 'all' tag
 which matches all sound fonts.
 */
public final class LegacyTag: Codable {
     private typealias UByte16 = (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                                  UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)

    /// Type of the unique key associated with a tag
    public typealias Key = UUID

    /// The 'All' tag to which all sound fonts belong
    public static let allTag = LegacyTag(nameProc: { Formatters.strings.allTagName },
                                         uuid: (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16))

    /// The 'Built-in' tag to which all packaged sound fonts belong
    public static let builtInTag = LegacyTag(nameProc: { Formatters.strings.builtInTagName },
                                             uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))

    /// A set containing the 'all' tag. This is a convenience for combining another tag with the 'all' tag.
    public static let allTagSet = Set([allTag.key, builtInTag.key])

    /// The unique key for the tag.
    public let key: Key

    /// The name of the tag. Unlike the key, the name can be changed.
    public var name: String

    /// Constructor for the 'all' tag.
    private init(nameProc: @escaping () -> String, uuid: UByte16) {
        self.key = UUID(uuid: uuid)
        self.name = nameProc()
        NotificationCenter.default.addObserver(forName: NSLocale.currentLocaleDidChangeNotification, object: nil,
                                               queue: nil) { _ in self.name = nameProc() }
    }

    /**
     Construct new tag instance.

     - parameter name: the name to show for the tag
     */
    public init(name: String) {
        var key = Key()
        while key == Self.allTag.key || key == Self.builtInTag.key { key = Key() }
        self.key = key
        self.name = name
    }
}

extension LegacyTag: Equatable {

    /**
     Allow for equality comparison based on tag key

     - parameter lhs: left-hand tag to compare
     - parameter rhs: right-hand tag to compare
     - returns: true if the tags are the same
     */
    public static func == (lhs: LegacyTag, rhs: LegacyTag) -> Bool { lhs.key == rhs.key }
}

extension LegacyTag: CustomStringConvertible {
    /// Custom description for Tag instances
    public var description: String { "Tag('\(name)')" }
}
