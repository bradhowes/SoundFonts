// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation
import os

/// Collection of Favorite instances created by the user.
final public class FavoriteCollection: Codable {
  private var favorites: [Favorite]

  /// Number of favorites defined
  var count: Int { favorites.count }

  init() {
    self.favorites = []
  }

  /**
   Obtain the index of the favorite that has the given key

   - parameter key: the key to look for
   - returns: the index of the favorite or None if the key was not found
   */
  func index(of key: Favorite.Key) -> Int? { favorites.firstIndex { $0.key == key } }

  /**
   Determine if the given key is in the collection of favorites.

   - parameter key: the key to look for
   - returns: true if the key matches
   */
  func contains(key: Favorite.Key) -> Bool { favorites.firstIndex { $0.key == key } != nil }

  /**
   Obtain the favorite at the given index.

   - parameter index: the index to use
   - returns: the favorite instance
   */
  func getBy(index: Int) -> Favorite { favorites[index] }

  /**
   Obtain the favorite by its key.

   - parameter key: the key to look for
   - returns: the optional favorite instance
   */
  func getBy(key: Favorite.Key) -> Favorite? {
    guard let index = index(of: key) else { return nil }
    return favorites[index]
  }

  /**
   Add a favorite to the end of the collection.

   - parameter favorite: the new favorite to add
   */
  func add(favorite: Favorite) {
    favorites.append(favorite)
    AskForReview.maybe()
  }

  /**
   Replace an existing entry with a new value.

   - parameter index: the location to replace
   - parameter favorite: the new value to store
   */
  func replace(index: Int, with favorite: Favorite) {
    favorites[index] = favorite
  }

  /**
   Move a favorite from one location to another

   - parameter from: index moving from
   - parameter to: index moving to
   */
  func move(from: Int, to: Int) {
    favorites.insert(favorites.remove(at: from), at: to)
    AskForReview.maybe()
  }

  /**
   Remove a favorite

   - parameter key: the key of the favorite to remove
   - returns: the instance that was removed from the collection
   */
  func remove(key: Favorite.Key) -> Favorite? {
    defer { AskForReview.maybe() }
    guard let index = index(of: key) else { return nil }
    return favorites.remove(at: index)
  }

  /**
   Remove a favorite

   - parameter index: the index of the favorite to remove
   - returns: the instance that was removed from the collection
   */
  func remove(at index: Int) -> Favorite {
    defer { AskForReview.maybe() }
    return favorites.remove(at: index)
  }

  /**
   Remove all favorites associated with a given sound font key

   - parameter soundFontKey: the key of the sound font being removed
   */
  func removeAll(associatedWith soundFontKey: SoundFont.Key) {
    findAll(associatedWith: soundFontKey).forEach { _ = self.remove(key: $0.key) }
  }

  /**
   Count the number of favorites associated with a given sound font key

   - parameter soundFontKey: the key of the sound font being queried
   - returns: count of associated favorites
   */
  func count(associatedWith soundFontKey: SoundFont.Key) -> Int {
    findAll(associatedWith: soundFontKey).count
  }
}

extension FavoriteCollection: CustomStringConvertible {

  public var description: String {
    "["
      + favorites.map { "\($0.soundFontAndPreset) '\($0.presetConfig.name)'" }.joined(separator: ",")
      + "]"
  }
}

extension FavoriteCollection {

  private func findAll(associatedWith soundFontKey: SoundFont.Key) -> [Favorite] {
    favorites.filter { $0.soundFontAndPreset.soundFontKey == soundFontKey }
  }
}
