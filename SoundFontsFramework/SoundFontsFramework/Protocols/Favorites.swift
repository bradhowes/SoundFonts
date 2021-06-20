// Copyright © 2019 Brad Howes. All rights reserved.

import UIKit

/// The different events which are emitted by a Favorites collection when the collection changes.
public enum FavoritesEvent {
  /// A new favorite has been added
  case added(index: Int, favorite: Favorite)
  /// A favorite has been selected
  case selected(index: Int, favorite: Favorite)
  /// A favorite will be edited
  case beginEdit(config: FavoriteEditor.Config)
  /// A favorite has changed
  case changed(index: Int, favorite: Favorite)
  /// A favorite has been removed
  case removed(index: Int, favorite: Favorite)
  /// All favorites that were associated with a sound font have been removed
  case removedAll(associatedWith: SoundFont)
  /// The collection of favorites has been restored from disk
  case restored

  /// Obtain the favorite instance that is associated with an event, if there is one.
  var favorite: Favorite? {
    switch self {
    case let .added(index: _, favorite: favorite): return favorite
    case let .selected(index: _, favorite: favorite): return favorite
    case let .changed(index: _, favorite: favorite): return favorite
    case let .removed(index: _, favorite: favorite): return favorite
    default: return nil
    }
  }
}

/// Actions available on a collection of Favorite instances. Supports subscribing to changes.
public protocol Favorites {

  /// True if the collection of favorites has been restored from disk
  var restored: Bool { get }

  /// Get number of favorites
  var count: Int { get }

  /**
   Determine if the given favorite key is in the collection.

   - parameter key: the key to look for
   - returns: true if it exists
   */
  func contains(key: Favorite.Key) -> Bool

  /**
   Obtain the index of the given Favorite in the collection.

   - parameter favorite: what to look for
   - returns: the position of the Favorite
   */
  func index(of favorite: Favorite.Key) -> Int

  /**
   Obtain the Favorite at the given index

   - parameter index: the location to get
   - returns: Favorite at the index
   */
  func getBy(index: Int) -> Favorite

  /**
   Obtain the Favorite by its key.

   - parameter key the key to look for
   - returns: Favorite with the given key
   */
  func getBy(key: Favorite.Key) -> Favorite

  /**
   Add a Favorite to the collection

   - parameter favorite: instance to add
   */
  func add(favorite: Favorite)

  /**
   Begin editing a Favorite

   - parameter config: the configuration to apply to the editor
   - parameter view: the UIView which started the editing
   */
  func beginEdit(config: FavoriteEditor.Config)

  /**
   Update the collection due to a change in the given Favorite

   - parameter index: the location where the Favorite should be
   - parameter config: the latest config settings
   */
  func update(index: Int, config: PresetConfig)

  /**
   Move a Favorite from one place in the collection to another.

   - parameter from: where the Favorite is coming from
   - parameter to: where the Favorite is moving to
   */
  func move(from: Int, to: Int)

  /**
   Update the visibility of a favorite.

   - parameter key: the key of the favorite to change
   - parameter state: the visibility state to use
   */
  func setVisibility(key: Favorite.Key, state: Bool)

  /**
   Set the effects configurations for a given favorite.

   - parameter favorite: the favorite to update
   - delay: the delay configuration to save
   - reverb: the reverb configuration to save
   */
  func setEffects(favorite: Favorite, delay: DelayConfig?, reverb: ReverbConfig?)

  /**
   The Favorite at the given index is selected by the user.

   - parameter index: the index that is selected
   */
  func selected(index: Int)

  /**
   Remove the Favorite at the given index.

   - parameter index: the index to remove
   */
  func remove(key: Favorite.Key)

  /**
   Remove all Favorite instances associated with the given SoundFont.

   - parameter associatedWith: the SoundFont to look for
   */
  func removeAll(associatedWith: SoundFont)

  /**
   Obtain a count of the number of Favorite instances associated with the given SoundFont.

   - parameter associatedWith: what to look for
   - returns: count
   */
  func count(associatedWith: SoundFont) -> Int

  /**
   Subscribe to notifications when the collection changes. The types of changes are defined in FavoritesEvent enum.

   - parameter subscriber: the object doing the monitoring
   - parameter notifier: the closure to invoke when a change takes place
   - returns: token that can be used to unsubscribe
   */
  @discardableResult
  func subscribe<O: AnyObject>(_ subscriber: O, notifier: @escaping (FavoritesEvent) -> Void)
  -> SubscriberToken

  func validate(_ soundFonts: SoundFonts)
}
