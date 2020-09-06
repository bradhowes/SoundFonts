// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation

/**
 Collection of SoundFont entities. The collection maintains a mapping between a SoundFont.Key (UUID) and a SoundFont
 instance. It also maintains an array of SoundFont.Key values that are ordered by SoundFont.name values.
 */
public final class SoundFontCollection: Codable {

    public typealias Element = SoundFont
    public typealias CatalogMap = [SoundFont.Key: SoundFont];
    public typealias SortedKeyArray = [SoundFont.Key];

    private var catalog: CatalogMap
    private var sortedKeys: SortedKeyArray

    /// Obtain the number of SoundFont instances in the collection
    public var count: Int { sortedKeys.count }

    /**
     Create a new collection.

     - parameter soundFonts: array of SoundFont instances
     */
    public init(soundFonts: [SoundFont]) {
        self.catalog = [SoundFont.Key: SoundFont](uniqueKeysWithValues: soundFonts.map { ($0.key, $0) })
        self.sortedKeys = soundFonts.sorted {
            $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }.map { $0.key }
    }

    public var soundFonts: [SoundFont] { sortedKeys.map { self.catalog[$0]! } }

    public func validate(_ soundFontAndPatch: SoundFontAndPatch) -> Bool {
        guard let soundFont = getBy(key: soundFontAndPatch.soundFontKey) else { return false }
        return soundFontAndPatch.patchIndex < soundFont.patches.count
    }

    /**
     Obtain the index of the given SoundFont.Key value.

     - parameter key: the key to look for
     - returns: index value if found, else nil
     */
    public func index(of key: SoundFont.Key) -> Int? { sortedKeys.firstIndex(of: key) }

    /**
     Obtain the index of a SoundFont wiith the given URL.

     - parameter url: the URL to look for
     - returns: index value if found, else nil
     */
    public func index(of url: URL) -> Int? {
        guard let found = catalog.first(where: { entry in
            entry.value.fileURL == url
        }) else {
            return nil
        }
        return index(of: found.key)
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
            catalog[$0]!.displayName.localizedCaseInsensitiveCompare(catalog[$1]!.displayName) == .orderedAscending
        }
    }
}
