// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation

struct SoundFontCollection: Codable {

    private var catalog: [UUID:SoundFont]
    private var sortedKeys: [UUID]

    var count: Int { sortedKeys.count }

    init(soundFonts: [SoundFont]) {
        self.catalog = Dictionary<UUID, SoundFont>.init(uniqueKeysWithValues: soundFonts.map { ($0.uuid, $0) })
        self.sortedKeys = soundFonts.sorted { $0.displayName < $1.displayName }.map { $0.uuid }
    }

    func index(of uuid: UUID) -> Int? { sortedKeys.firstIndex(of: uuid) }

    func getBy(index: Int) -> SoundFont { catalog[sortedKeys[index]]! }

    func getBy(uuid: UUID) -> SoundFont? { catalog[uuid] }

    mutating func add(_ soundFont: SoundFont) -> Int {
        catalog[soundFont.uuid] = soundFont
        let index = insertionIndex(of: soundFont.uuid)
        sortedKeys.insert(soundFont.uuid, at: index)
        return index
    }

    mutating func remove(_ index: Int) -> SoundFont {
        let uuid = sortedKeys.remove(at: index)
        return catalog.removeValue(forKey: uuid)!
    }

    mutating func rename(_ index: Int, name: String) -> (Int, SoundFont) {
        let uuid = sortedKeys.remove(at: index)

        var soundFont = catalog[uuid]!
        soundFont.displayName = name

        let newIndex = insertionIndex(of: soundFont.uuid)
        sortedKeys.insert(soundFont.uuid, at: newIndex)
        return (newIndex, soundFont)
    }

    private func insertionIndex(of uuid: UUID) -> Int {
        sortedKeys.insertionIndex(of: uuid) { catalog[$0]!.displayName < catalog[$1]!.displayName }
    }
}
