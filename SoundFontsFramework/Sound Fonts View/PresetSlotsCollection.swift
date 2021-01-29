// Copyright © 2021 Brad Howes. All rights reserved.

import UIKit
import os

/// Number of sections we partition patches into
private let sectionSize = 20

private enum Slot {
    case preset(presetIndex: Int)
    case favorite(key: LegacyFavorite.Key)
}

extension Slot {
    var presetIndex: Int? {
        switch self {
        case .preset(let presetIndex): return presetIndex
        case .favorite: return nil
        }
    }
}

private extension Array where Element == Slot {
    subscript(indexPath: IndexPath) -> Element { self[indexPath.presetIndex] }
}

private extension IndexPath {
    init(presetIndex: Int) {
        let section = presetIndex / sectionSize
        self.init(row: presetIndex - section * sectionSize, section: section)
    }

    var presetIndex: Int { section * sectionSize + row }
}

final class PresetSlotsCollection: NSObject {
    private lazy var log = Logging.logger("PresetSlotsCollection")

    private let soundFonts: SoundFonts
    private var activeSoundFont: LegacySoundFont?
    private var slots: [Slot] = .init()
    private var sectionRowCounts = [Int]()

    init(soundFonts: SoundFonts) {
        self.soundFonts = soundFonts
        super.init()
    }
}

extension PresetSlotsCollection {

    func setCollection(using soundFont: LegacySoundFont?, visibilityEditingMode: Bool = false) {
        activeSoundFont = soundFont
        let source = soundFont?.patches ?? []
        slots = source.filter {
            $0.isVisible == true || visibilityEditingMode
        } .map {
            .preset(presetIndex: $0.soundFontIndex)
        }
        updateSectionRowCounts()
    }

    private func updateSectionRowCounts() {
        let numFullSections = slots.count / sectionSize
        sectionRowCounts = [Int](repeating: sectionSize, count: numFullSections)
        sectionRowCounts.append(slots.count - numFullSections * sectionSize)
    }

    func setSlotVisibility(at indexPath: IndexPath, state: Bool) {
        guard let soundFont = activeSoundFont,
              let presetIndex = slots[indexPath].presetIndex else { return }
        let soundFontAndPatch = SoundFontAndPatch(soundFontKey: soundFont.key, patchIndex: presetIndex)
        soundFonts.setVisibility(soundFontAndPatch: soundFontAndPatch, state: state)
    }

    func performChanges(enteringEditingMode: Bool) -> (insertions: [IndexPath], deletions: [IndexPath]) {
        guard let source = activeSoundFont?.patches.reversed().enumerated() else {
            return ([], [])
        }

        var insertions = [IndexPath]()
        var deletions = [IndexPath]()

        for (presetIndex, preset) in source {
            if preset.isVisible == false {
                if enteringEditingMode {
                    slots.insert(.preset(presetIndex: presetIndex), at: presetIndex)
                    let indexPath = IndexPath(presetIndex: presetIndex)
                    insertions.append(indexPath)
                    sectionRowCounts[indexPath.section] += 1
                }
                else {
                    slots.remove(at: presetIndex)
                    let indexPath = IndexPath(presetIndex: presetIndex)
                    deletions.append(indexPath)
                    sectionRowCounts[indexPath.section] -= 1
                }
            }
            else {
                for (favoriteIndex, favoriteKey) in preset.favorites.reversed().enumerated() {
                    if enteringEditingMode {
                        slots.remove(at: presetIndex + favoriteIndex + 1)
                        let indexPath = IndexPath(presetIndex: presetIndex + favoriteIndex + 1)
                        deletions.append(indexPath)
                        sectionRowCounts[indexPath.section] -= 1
                    }
                    else {
                        slots.insert(.favorite(key: favoriteKey),
                                     at: presetIndex + favoriteIndex + 1)
                        let indexPath = IndexPath(presetIndex: presetIndex + favoriteIndex + 1)
                        insertions.append(indexPath)
                        sectionRowCounts[indexPath.section] += 1
                    }
                }
            }
        }
        return (insertions, deletions)
    }
}
