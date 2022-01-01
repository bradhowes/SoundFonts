// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation

/// Collection of SoundFont entities. The collection maintains a mapping between a SoundFont.Key (UUID) and a SoundFont
/// instance. It also maintains an array of SoundFont.Key values that are ordered by SoundFont.name values.
public final class SoundFontCollection: Codable {
  public typealias Element = SoundFont
  public typealias CatalogMap = [SoundFont.Key: SoundFont]
  public typealias SortedKeyArray = [SoundFont.Key]

  /// Mapping of SoundFont UUID (generated at installation) and the SoundFont instance
  private var catalog: CatalogMap

  /// Sorted names of the SoundFont instances
  private var sortedKeys: SortedKeyArray

  /// True if there are no SoundFont instances in the collection
  public var isEmpty: Bool { sortedKeys.isEmpty }

  /// The number of SoundFont instances in the collection
  public var count: Int { sortedKeys.count }

  /// Obtain the first preset of the first sound font if one exists.
  public var defaultPreset: SoundFontAndPreset? { isEmpty ? nil : getBy(index: 0)[0] }

  /**
   Create a new collection.

   - parameter soundFonts: array of SoundFont instances
   */
  public init(soundFonts: [SoundFont]) {
    self.catalog = [SoundFont.Key: SoundFont](uniqueKeysWithValues: soundFonts.map { ($0.key, $0) })
    self.sortedKeys = soundFonts.sorted {
      $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
    }.map { $0.key }
  }

  /// Immutable array of SoundFont instances, ordered by their names
  public var soundFonts: [SoundFont] { sortedKeys.map { self.catalog[$0]! } }

  /**
   Obtain the index of the given SoundFont.Key value.

   - parameter key: the key to look for
   - returns: index value if found, else nil
   */
  public func firstIndex(of key: SoundFont.Key) -> Int? { sortedKeys.firstIndex(of: key) }

  /**
   Obtain the index of a SoundFont with the given URL.

   - parameter url: the URL to look for
   - returns: index value if found, else nil
   */
  public func index(of url: URL) -> Int? {
    guard let found = (catalog.first { entry in entry.value.fileURL.absoluteString == url.absoluteString }) else {
      return nil
    }
    return firstIndex(of: found.key)
  }

  /**
   Obtain a SoundFont by its unique key or its name. The reason for the latter is to support the case where a reference
   is used on another device (SoundFont keys are unique per device).

   - parameter soundFontAndPreset: the bookmark to resolve
   - returns: the SoundFont value found or nil
   */
  public func getBy(soundFontAndPreset: SoundFontAndPreset) -> SoundFont? {
    catalog[soundFontAndPreset.soundFontKey] ?? soundFonts.first {
      $0.originalDisplayName == soundFontAndPreset.soundFontName
    }
  }

  /**
   Obtain a SoundFont by its (sorted) index value

   - parameter index: the SoundFont.Key to look for
   - returns: the SoundFont value found
   */
  public func getBy(index: Int) -> SoundFont { catalog[sortedKeys[index]]! }

  /**
   Obtain a SoundFont by its UUID value

   - parameter key: the UUID to look for
   - returns: the SoundFont instance found, else nil
   */
  public func getBy(key: SoundFont.Key) -> SoundFont? { catalog[key] }

  /**
   Add a new SoundFont definition to the collection.

   - parameter soundFont: the SoundFont to add
   - returns: index of the SoundFont in the collection
   */
  public func add(_ soundFont: SoundFont) -> Int {
    catalog[soundFont.key] = soundFont
    let index = insertionIndex(of: soundFont.key)
    sortedKeys.insert(soundFont.key, at: index)
    AskForReview.maybe()
    return index
  }

  /**
   Remove a SoundFont from the collection.

   - parameter index: the index of the SoundFont to remove.
   - returns: the removed SoundFont instance, nil if not found.
   */
  public func remove(_ index: Int) -> SoundFont? {
    let key = sortedKeys.remove(at: index)
    AskForReview.maybe()
    return catalog.removeValue(forKey: key)
  }

  /**
   Rename an existing SoundFont.

   - parameter index: the index of the SoundFont to change
   - parameter name: the new name for the SoundFont
   - returns: 2-tuple containing the new index of the SoundFont due to name reordering, and the SoundFont itself
   */
  public func rename(_ index: Int, name: String) -> (Int, SoundFont) {
    let key = sortedKeys.remove(at: index)

    let soundFont = catalog[key]!
    soundFont.displayName = name

    let newIndex = insertionIndex(of: soundFont.key)
    sortedKeys.insert(soundFont.key, at: newIndex)

    AskForReview.maybe()
    return (newIndex, soundFont)
  }

  /**
   Obtain the index in the collection to insert a SoundFont key so that the alphabetical ordering of the collection
   is maintained

   - parameter key: the name of the SoundFont to insert
   - returns: the index in the collection to insert
   */
  private func insertionIndex(of key: SoundFont.Key) -> Int {
    sortedKeys.insertionIndex(of: key) {
      catalog[$0]!.displayName.localizedCaseInsensitiveCompare(catalog[$1]!.displayName)
        == .orderedAscending
    }
  }
}

extension SoundFontCollection: CustomStringConvertible {
  public var description: String {
    "[" + catalog.map { "\($0.key): '\($0.value.displayName)'" }.joined(separator: ",") + "]"
  }
}
