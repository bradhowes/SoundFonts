// Copyright © 2021 Brad Howes. All rights reserved.

import Foundation
import os

/// Collection of Tag instances.
public final class TagCollection: Codable {
  private lazy var log: OSLog = Logging.logger("TagCollection")

  private var tags: [Tag]

  /// Contains true if the collection is empty
  public var isEmpty: Bool { return tags.isEmpty }

  /// Number of tags in the collection
  public var count: Int { tags.count }

  /**
   Initialize new collection.

   - parameter tags: collection to use
   */
  public init(tags: [Tag] = []) { self.tags = tags }

  /**
   Obtain a list of Tag names from a set of Tag keys

   - parameter keys: the keys of the Tags to include
   - returns: list of Tag names
   */
  public func names(of keys: Set<Tag.Key>) -> [String] {
    keys.compactMap { getBy(key: $0)?.name }
  }

  /**
   Obtain the index in the collection for a given Tag key

   - parameter key: the Tag key to look for
   - returns: the optional index value
   */
  public func index(of key: Tag.Key) -> Int? { tags.firstIndex { $0.key == key } }

  /**
   Obtain a Tag instance at the given index.

   - parameter index: the collection index to get
   - returns: the Tag value
   */
  public func getBy(index: Int) -> Tag { tags[index] }

  /**
   Obtain the Tag that has the given key

   - parameter key: the key to look for
   - returns: the optional Tag that was found
   */
  public func getBy(key: Tag.Key) -> Tag? { tags.first { $0.key == key } }

  /**
   Add a new Tag to the collection

   - parameter tag: the Tag to add
   - returns: the position in the collection of the tag
   */
  public func append(_ tag: Tag) -> Int {
    tags.append(tag)
    return count - 1
  }

  /**
   Insert a tag in a given place in the collection.

   - parameter tag: the Tag to insert
   - parameter index: the location to insert it
   */
  public func insert(_ tag: Tag, at index: Int) { tags.insert(tag, at: index) }

  /**
   Remove a tag from the collection.

   - parameter index: the location to remove
   - returns: the Tag that was removed
   */
  public func remove(at index: Int) -> Tag { tags.remove(at: index) }

  /**
   Rename a tag.

   - parameter index: the index of the Tag to rename
   - parameter name: the new name to use
   */
  public func rename(_ index: Int, name: String) { tags[index].name = name }
}

extension TagCollection: CustomStringConvertible {
  /// Custom description string for the tag collection
  public var description: String { tags.description }
}
