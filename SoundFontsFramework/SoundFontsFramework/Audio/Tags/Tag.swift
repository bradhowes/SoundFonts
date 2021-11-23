// Copyright © 2021 Brad Howes. All rights reserved.

import Foundation

/// A tag is just a unique name that can be associated with zero or more sound fonts. By default there is an 'all' tag
/// which matches all sound fonts, and a 'built-in' tag that shows just those that come with the app.
public final class Tag: Codable {

  private typealias UByte16 = (
    UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
    UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8
  )

  /// Type of the unique key associated with a tag
  public typealias Key = UUID

  /// The 'All' tag to which all sound fonts belong
  public static let allTag = Tag(
    nameProc: { Formatters.strings.allTagName },
    uuid: (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16))

  /// The 'Built-in' tag to which all packaged sound fonts belong
  public static let builtInTag = Tag(
    nameProc: { Formatters.strings.builtInTagName },
    uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))

  /// A set containing the two tags above.
  public static let stockTagSet = Set([allTag.key, builtInTag.key])

  /// A set containing just the 'all' tag above. This is a convenience for generating the set of tags for a sound font.
  public static let allTagSet = Set([allTag.key])

  /// The unique key for the tag.
  public let key: Key

  /// The name of the tag. Unlike the key, the name can be changed.
  public var name: String

  /// True if the tag is a user-created tag, with a name that they can edit.
  public var isUserTag: Bool { !Self.stockTagSet.contains(self.key) }

  /**
   Constructor for the built-in tags.

   - parameter nameProc: method/closure to invoke to get the names in a locale-dependent manner.
   - parameter uuid: the unique UUID for the tag
   */
  private init(nameProc: @escaping () -> String, uuid: UByte16) {
    self.key = UUID(uuid: uuid)
    self.name = nameProc()
    NotificationCenter.default.addObserver(
      forName: NSLocale.currentLocaleDidChangeNotification, object: nil,
      queue: nil
    ) { [weak self] _ in self?.name = nameProc() }
  }

  /**
   Construct new tag instance.

   - parameter name: the name to show for the tag
   */
  public init(name: String) {
    var key = Key()
    while Self.stockTagSet.contains(key) { key = Key() }
    self.key = key
    self.name = name
  }
}

extension Tag: Equatable {

  /**
   Allow for equality comparison based on tag key

   - parameter lhs: left-hand tag to compare
   - parameter rhs: right-hand tag to compare
   - returns: true if the tags are the same
   */
  public static func == (lhs: Tag, rhs: Tag) -> Bool { lhs.key == rhs.key }
}

extension Tag: CustomStringConvertible {
  /// Custom description for Tag instances
  public var description: String { "Tag('\(name)')" }
}

extension Tag.Key: SettingSerializable {

  public static func register(key: String, value: UUID, userDefaults: UserDefaults) {
    userDefaults.register(defaults: [key: value.uuidString])
  }

  public static func get(key: String, userDefaults: UserDefaults) -> Tag.Key {
    Tag.Key(uuidString: userDefaults.string(forKey: key)!) ?? Tag.allTag.key
  }

  public static func set(key: String, value: Tag.Key, userDefaults: UserDefaults) {
    userDefaults.set(value.uuidString, forKey: key)
  }
}
