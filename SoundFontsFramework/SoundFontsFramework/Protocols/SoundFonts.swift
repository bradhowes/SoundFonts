// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation

/// The different events which are emitted by a SoundFonts collection when the collection changes.
public enum SoundFontsEvent {

  /// New SoundFont added to the collection
  case added(new: Int, font: SoundFont)

  /// Existing SoundFont moved from one position in the collection to another due to name change
  case moved(old: Int, new: Int, font: SoundFont)

  /// Existing SoundFont instance removed from the collection
  case removed(old: Int, font: SoundFont)

  /// Hidden presets were restored and made visible in a given sound font
  case unhidPresets(font: SoundFont)

  /// A preset in a sound font changed
  case presetChanged(font: SoundFont, index: Int)

  /// Sound font collection was restored from disk and is now safe to use
  case restored
}

/// Actions available on a collection of SoundFont instances. Supports subscribing to changes.
public protocol SoundFonts: AnyObject {

  /// True if the collection of sound fonts has been restored
  var restored: Bool { get }
  /// Collection of all of the sound fount names
  var soundFontNames: [String] { get }
  /// The default preset to use if there is not one
  var defaultPreset: SoundFontAndPreset? { get }

  /**
     Validate the sound font collection, making sure that everything is in order. Removes any stray tags or favorites.

     - parameter favorites: collection of favorites
     - parameter tags: collection of tags
     */
  func validateCollections(favorites: Favorites, tags: Tags)

  /**
     Obtain the index in the collection of a SoundFont with the given Key.

     - parameter of: the key to look for
     - returns: the index of the matching entry or nil if not found
     */
  func firstIndex(of: SoundFont.Key) -> Int?

  /**
     Obtain the SoundFont in the collection by its unique key

     - parameter key: the key to look for
     - returns: the index of the matching entry or nil if not found
     */
  func getBy(key: SoundFont.Key) -> SoundFont?

  /**
     Obtain an actual preset object from the given SoundFontAndPreset value.

     - parameter soundFontAndPreset: reference to a preset in a sound font
     - returns: Preset object that corresponds to the given value
     */
  func resolve(soundFontAndPreset: SoundFontAndPreset) -> Preset?

  /**
     Obtain the collection of sound fonts that contains the given tag.

     - parameter tag: the tag to filter on
     - returns: collection of sound font instances that have the given tag
     */
  func filtered(by tag: Tag.Key) -> [SoundFont.Key]

  func filteredIndex(index: Int, tag: Tag.Key) -> Int

  /**
     Get the names of the given sound fonts.

     - parameter keys: the sound font keys to look for
     - returns: list of sound font names
     */
  func names(of keys: [SoundFont.Key]) -> [String]

  /**
     Add a new SoundFont.

     - parameter url: the URL of the file containing SoundFont (SF2) data

     - returns: 2-tuple containing the index in the collection where the new SoundFont was inserted, and the SoundFont
     instance created from the raw data
     */
  func add(url: URL) -> Result<(Int, SoundFont), SoundFontFileLoadFailure>

  /**
     Remove the SoundFont at the given index

     - parameter index: the location to remove
     */
  func remove(key: SoundFont.Key)

  /**
     Change the name of a SoundFont

     - parameter index: location of the SoundFont to edit
     - parameter name: new name to use
     */
  func rename(key: SoundFont.Key, name: String)

  /**
     Remove an association between a sound font and a tag

     - parameter tag: the tag to remove
     */
  func removeTag(_ tag: Tag.Key)

  /**
     Create a new favorite for a sound font preset.

     - parameter soundFontAndPreset: the preset to make a favorite
     - parameter keyboardLowestNote: the lowest note to use for the preset
     - returns: new Favorite
     */
  func createFavorite(soundFontAndPreset: SoundFontAndPreset, keyboardLowestNote: Note?) -> Favorite?

  /**
     Remove an existing favorite.

     - parameter soundFontAndPreset: the preset that was used to create the favorite
     - parameter key: the unique key of the favorite to remove
     */
  func deleteFavorite(soundFontAndPreset: SoundFontAndPreset, key: Favorite.Key)

  /**
     Update the configuration of a preset.

     - parameter soundFontAndPreset: the preset to update
     - parameter config: the configuration to use
     */
  func updatePreset(soundFontAndPreset: SoundFontAndPreset, config: PresetConfig)

  /**
     Set the preset visibility.

     - parameter soundFontAndPreset: the preset to change
     - parameter state: the new visibility state for the preset
     */
  func setVisibility(soundFontAndPreset: SoundFontAndPreset, state: Bool)

  /**
     Make all presets of a given SoundFont visible.

     - parameter key: the unique key of the SoundFont to change
     */
  func makeAllVisible(key: SoundFont.Key)

  /**
     Attach effect configurations to a preset.

     - parameter soundFontAndPreset: the preset to change
     - parameter delay: the configuration for the delay
     - parameter reverb: the configuration for the reverb
     */
  func setEffects(soundFontAndPreset: SoundFontAndPreset, delay: DelayConfig?, reverb: ReverbConfig?)

  /**
     Reload the embedded contents of the sound font

     - parameter key: the sound font to reload
     */
  func reloadEmbeddedInfo(key: SoundFont.Key)

  /// Determine if there are any bundled fonts in the collection
  var hasAnyBundled: Bool { get }

  /// Determine if all bundled fonts are in the collection
  var hasAllBundled: Bool { get }

  /**
     Remove all built-in SoundFont entries.
     */
  func removeBundled()

  /**
     Restore built-in SoundFonts.
     */
  func restoreBundled()

  /**
     Export all sound fonts in the collection to a local documents directory that the user can access.

     - returns: 2-tuple containing a counter of the number of successful exports and the total number that was
     attempted
     */
  func exportToLocalDocumentsDirectory() -> (good: Int, total: Int)

  /**
     Import sound fonts found in the local documents directory for the app.

     - returns: 2-tuple containing a counter of the number of successful exports and the total number that was
     attempted
     */
  func importFromLocalDocumentsDirectory() -> (good: Int, total: Int)

  /**
     Subscribe to notifications when the collection changes. The types of changes are defined in SoundFontsEvent enum.

     - parameter subscriber: the object doing the monitoring
     - parameter notifier: the closure to invoke when a change takes place
     - returns: token that can be used to unsubscribe
     */
  @discardableResult
  func subscribe<O: AnyObject>(_ subscriber: O, notifier: @escaping (SoundFontsEvent) -> Void)
    -> SubscriberToken
}
