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

  func contains(key: Favorite.Key) -> Bool { favorites.firstIndex { $0.key == key } != nil }

  func index(of key: Favorite.Key) -> Int {
    guard let index = (favorites.firstIndex { $0.key == key }) else {
      fatalError("internal inconsistency - missing favorite key '\(key.uuidString)'")
    }
    return index
  }

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
  func getBy(key: Favorite.Key) -> Favorite { getBy(index: index(of: key)) }

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

  func move(from: Int, to: Int) {
    favorites.insert(favorites.remove(at: from), at: to)
    AskForReview.maybe()
  }

  func remove(key: Favorite.Key) -> Favorite {
    defer { AskForReview.maybe() }
    return favorites.remove(at: index(of: key))
  }

  func remove(at index: Int) -> Favorite {
    defer { AskForReview.maybe() }
    return favorites.remove(at: index)
  }

  func removeAll(associatedWith soundFontKey: SoundFont.Key) {
    findAll(associatedWith: soundFontKey).forEach { _ = self.remove(key: $0.key) }
  }

  func count(associatedWith soundFontKey: SoundFont.Key) -> Int {
    findAll(associatedWith: soundFontKey).count
  }
}

extension FavoriteCollection: CustomStringConvertible {
  public var description: String {
    "["
      + favorites.map { "\($0.soundFontAndPatch) '\($0.presetConfig.name)'" }.joined(separator: ",")
      + "]"
  }
}

extension FavoriteCollection {

  private func findAll(associatedWith soundFontKey: SoundFont.Key) -> [Favorite] {
    favorites.filter { $0.soundFontAndPatch.soundFontKey == soundFontKey }
  }
}
