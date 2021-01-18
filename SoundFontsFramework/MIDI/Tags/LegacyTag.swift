// Copyright © 2018 Brad Howes. All rights reserved.

import Foundation

public final class LegacyTag: Codable {

    public typealias Key = UUID

    public let key: Key
    public var name: String

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
