// Copyright © 2018 Brad Howes. All rights reserved.

import Foundation

public final class LegacyTag: Codable {
    public typealias Key = UUID

    public static let allTag = LegacyTag()
    public static let allTagSet = Set([allTag.key])

    public let key: Key
    public var name: String

    private init() {
        let uuid: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) =
            (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16)
        key = UUID(uuid: uuid)
        name = "All"
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
