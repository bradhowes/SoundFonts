// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation

/// The various tag events that can happen.
public enum TagsEvent: CustomStringConvertible {

  /// New tag added
  case added(new: Int, tag: Tag)
  /// Tag moved
  case moved(old: Int, new: Int, tag: Tag)
  /// Tag name changed
  case changed(index: Int, tag: Tag)
  /// Tag removed
  case removed(old: Int, tag: Tag)
  /// Tags were restored from disk / configuration
  case restored

  public var description: String {
    switch self {
    case let .added(new, tag): return "<TagsEvent: added \(new) '\(tag)'>"
    case let .moved(old, new, tag): return "<TagsEvent: moved \(old) \(new) '\(tag)'>"
    case let .changed(index, tag): return "<TagsEvent: changed \(index) '\(tag)'>"
    case let .removed(old, tag): return "<TagsEvent: removed \(old) '\(tag)'>"
    case .restored: return "<TagsEvent: restored>"
    }
  }
}

/// Protocol for activity involving sound font tags.
public protocol TagsProvider: AnyObject {

  /// True if the tags collection has been restored
  var isRestored: Bool { get }
  /// True if there are no tags in the collection
  var isEmpty: Bool { get }
  /// The number of tags in the collection
  var count: Int { get }

  /**
   Obtain the names of tags in the given collection.

   - parameter keys: the collection to work with
   - returns: list of strings
   */
  func names(of keys: Set<Tag.Key>) -> [String]

  /**
   Get the index for the given tag.

   - parameter of: the tag to search for
   - returns: the option index of the tag
   */
  func index(of: Tag.Key) -> Int?

  /**
   Get the tag at a given index.

   - parameter index: the index to fetch
   - returns tag at the index
   */
  func getBy(index: Int) -> Tag

  /**
   Get the tag by its key.

   - parameter key: the key of the tag to get
   - returns: tag with the given key
   */
  func getBy(key: Tag.Key) -> Tag?

  /**
   Add a tag to the collection.

   - parameter tag: the tag to add
   - returns: index of the new tag
   */
  func append(_ tag: Tag) -> Int

  /**
   Remove the tag at the given index.

   - parameter index: the index to remove
   - returns: tag that was removed
   */
  @discardableResult
  func remove(at index: Int) -> Tag

  /**
   Rename a tag.

   - parameter index: the index of the tag to rename
   - parameter name: the new name to use
   */
  func rename(_ index: Int, name: String)

  /**
   Insert a tag at the given index

   - parameter tag: the tag to insert
   - parameter index: the location to insert it
   */
  func insert(_ tag: Tag, at index: Int)

  /**
   Obtain the set of tags that correspond to a set of indices.

   - parameter indices: the indices to fetch
   - returns: set of tags
   */
  func keySet(of indices: Set<Int>) -> Set<Tag.Key>

  /**
   Allow subscriptions for tag collection changes.

   - parameter subscriber: the object that is subscribing
   - parameter notifier: the function or closure to invoke when an even takes place
   - returns: token that identifies the subscription and can be used to unsubscribe
   */
  @discardableResult
  func subscribe<O: AnyObject>(_ subscriber: O, notifier: @escaping (TagsEvent) -> Void) -> SubscriberToken

  func validate()
}
