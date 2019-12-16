// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation

final class SoundFontCollection: Codable {

    private var catalog: [SoundFont.Key:SoundFont]
    private var sortedKeys: [SoundFont.Key]

    var count: Int { sortedKeys.count }

    init(soundFonts: [SoundFont]) {
        self.catalog = Dictionary<SoundFont.Key, SoundFont>.init(uniqueKeysWithValues: soundFonts.map { ($0.key, $0) })
        self.sortedKeys = soundFonts.sorted { $0.displayName < $1.displayName }.map { $0.key }
    }

    func index(of key: SoundFont.Key) -> Int? { sortedKeys.firstIndex(of: key) }

    func getBy(index: Int) -> SoundFont { catalog[sortedKeys[index]]! }

    func getBy(uuid: UUID) -> SoundFont? { catalog[uuid] }

    func add(_ soundFont: SoundFont) -> Int {
        catalog[soundFont.key] = soundFont
        let index = insertionIndex(of: soundFont.key)
        sortedKeys.insert(soundFont.key, at: index)
        return index
    }

    func remove(_ index: Int) -> SoundFont? {
        let uuid = sortedKeys.remove(at: index)
        return catalog.removeValue(forKey: uuid)
    }

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
