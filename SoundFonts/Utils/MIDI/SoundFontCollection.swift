// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation

/**
 Collection of SoundFont entities. The collection maintains a mapping between a SoundFont.Key (UUID) and a SoundFont
 instance. It also maintains an array of SoundFont.Key values that are ordered by SoundFont.name values.
 */
final class SoundFontCollection: Codable {

    private var catalog: [SoundFont.Key: SoundFont]
    private var sortedKeys: [SoundFont.Key]

    var count: Int { sortedKeys.count }

    init(soundFonts: [SoundFont]) {
        self.catalog = [SoundFont.Key: SoundFont](uniqueKeysWithValues: soundFonts.map { ($0.key, $0) })
        self.sortedKeys = soundFonts.sorted { $0.displayName < $1.displayName }.map { $0.key }
    }

    /**
     Obtain the index of the given SoundFont.Key value.

     - parameter key: the key to look for
     - returns index value if found, else nil
     */
    func index(of key: SoundFont.Key) -> Int? { sortedKeys.firstIndex(of: key) }

    /**
     Obtain a SoundFont by its (sorted) index value

     - parameter index: the SoundFont.Key to look for
     - returns the SoundFont value found
     */
    func getBy(index: Int) -> SoundFont { catalog[sortedKeys[index]]! }

    /**
     Obtain a SoundFont by its UUID value

     - parameter key: the UUID to look for
     - returns the SoundFont instance found, else nil
     */
    func getBy(key: SoundFont.Key) -> SoundFont? { catalog[key] }

    /**
     Add a new SoundFont definition to the collection.

     - parameter soundFont: the SoundFont to add
     - returns index of the SoundFont in the collection
     */
    func add(_ soundFont: SoundFont) -> Int {
        catalog[soundFont.key] = soundFont
        let index = insertionIndex(of: soundFont.key)
        sortedKeys.insert(soundFont.key, at: index)
        return index
    }

    /**
     Remove a SoundFont from the collection.

     - parameter index: the index of the SoundFont to remove.
     - returns the removed SoundFont instance, nil if not found.
     */
    func remove(_ index: Int) -> SoundFont? {
        let key = sortedKeys.remove(at: index)
        return catalog.removeValue(forKey: key)
    }

    /**
     Rename an existing SoundFont.

     - parameter index: the index of the SoundFont to change
     - parameter name: the new name for the SoundFont
     - returns 2-tuple containing the new index of the SoundFont due to name reordering, and the SoundFont itself
     */
    func rename(_ index: Int, name: String) -> (Int, SoundFont) {
        let key = sortedKeys.remove(at: index)

        let soundFont = catalog[key]!
        soundFont.displayName = name

        let newIndex = insertionIndex(of: soundFont.key)
        sortedKeys.insert(soundFont.key, at: newIndex)
        return (newIndex, soundFont)
    }

    private func insertionIndex(of key: SoundFont.Key) -> Int {
        sortedKeys.insertionIndex(of: key) { catalog[$0]!.displayName < catalog[$1]!.displayName }
    }
}
