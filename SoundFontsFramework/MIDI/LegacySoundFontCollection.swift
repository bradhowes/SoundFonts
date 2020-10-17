// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation

/**
 Collection of SoundFont entities. The collection maintains a mapping between a SoundFont.Key (UUID) and a SoundFont
 instance. It also maintains an array of SoundFont.Key values that are ordered by SoundFont.name values.
 */
public final class LegacySoundFontCollection: Codable, CustomStringConvertible {

    public var description: String {
        "[" + catalog.map { "\(String.pointer($0.value)) '\($0.value.displayName)'" }.joined(separator: ",") + "]"
    }

    public typealias Element = LegacySoundFont
    public typealias CatalogMap = [LegacySoundFont.Key: LegacySoundFont]
    public typealias SortedKeyArray = [LegacySoundFont.Key]

    private var catalog: CatalogMap
    private var sortedKeys: SortedKeyArray

    public var isEmpty: Bool { return sortedKeys.isEmpty }

    /// Obtain the number of SoundFont instances in the collection
    public var count: Int { sortedKeys.count }

    /// Obtain the first preset of the first sound font if one exists.
    public var defaultPreset: SoundFontAndPatch? { isEmpty ? nil : getBy(index: 0).makeSoundFontAndPatch(at: 0) }

    /**
     Create a new collection.

     - parameter soundFonts: array of SoundFont instances
     */
    public init(soundFonts: [LegacySoundFont]) {
        self.catalog = [LegacySoundFont.Key: LegacySoundFont](uniqueKeysWithValues: soundFonts.map { ($0.key, $0) })
        self.sortedKeys = soundFonts.sorted {
            $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }.map { $0.key }
    }

    public var soundFonts: [LegacySoundFont] { sortedKeys.map { self.catalog[$0]! } }

    public func validate(_ soundFontAndPatch: SoundFontAndPatch) -> Bool {
        guard let soundFont = getBy(key: soundFontAndPatch.soundFontKey) else { return false }
        return soundFontAndPatch.patchIndex < soundFont.patches.count
    }

    /**
     Obtain the index of the given SoundFont.Key value.

     - parameter key: the key to look for
     - returns: index value if found, else nil
     */
    public func index(of key: LegacySoundFont.Key) -> Int? { sortedKeys.firstIndex(of: key) }

    /**
     Obtain the index of a SoundFont wiith the given URL.

     - parameter url: the URL to look for
     - returns: index value if found, else nil
     */
    public func index(of url: URL) -> Int? {
        guard let found = catalog.first(where: { entry in entry.value.fileURL.absoluteString == url.absoluteString }) else { return nil }
        return index(of: found.key)
    }

    /**
     Obtain a SoundFont by its (sorted) index value

     - parameter index: the SoundFont.Key to look for
     - returns: the SoundFont value found
     */
    public func getBy(index: Int) -> LegacySoundFont { catalog[sortedKeys[index]]! }

    /**
     Obtain a SoundFont by its UUID value

     - parameter key: the UUID to look for
     - returns: the SoundFont instance found, else nil
     */
    public func getBy(key: LegacySoundFont.Key) -> LegacySoundFont? { catalog[key] }

    /**
     Add a new SoundFont definition to the collection.

     - parameter soundFont: the SoundFont to add
     - returns: index of the SoundFont in the collection
     */
    public func add(_ soundFont: LegacySoundFont) -> Int {
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
    public func remove(_ index: Int) -> LegacySoundFont? {
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
    public func rename(_ index: Int, name: String) -> (Int, LegacySoundFont) {
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
    private func insertionIndex(of key: LegacySoundFont.Key) -> Int {
        sortedKeys.insertionIndex(of: key) {
            catalog[$0]!.displayName.localizedCaseInsensitiveCompare(catalog[$1]!.displayName) == .orderedAscending
        }
    }
}
