// Copyright © 2022 Brad Howes. All rights reserved.

import Foundation
import os.log

/**
 Performs the necessary table edits involved before and after visibility editing.
 */
struct PresetsTableRowVisibilityEditor {
  private let log: Logger = Logging.logger("PresetsTableRowVisibilityEditor")
  private(set) var viewSlots: [PresetViewSlot]
  private(set) var sectionRowCounts: [Int]
  private let soundFont: SoundFont
  private let favorites: FavoritesProvider

  init(viewSlots: [PresetViewSlot], sectionRowCounts: [Int], soundFont: SoundFont, favorites: FavoritesProvider) {
    self.viewSlots = viewSlots
    self.sectionRowCounts = sectionRowCounts
    self.soundFont = soundFont
    self.favorites = favorites
  }

  /**
   Begin editing. Insert rows for presets that are currently hidden from view. Note that the updates to the section row
   counters is temporary but necessary to keep iOS from throwing an exception due to internal inconsistencies.

   - returns: the list of indices that were added
   */
  mutating func begin() -> [IndexPath] {
    log.debug("begin BEGIN")
    var tableViewChanges = [IndexPath]()
    var slotIndex: PresetViewSlotIndex = 0

    func processPresetConfig(_ presetConfig: PresetConfig, slotGenerator: () -> PresetViewSlot) {
      guard presetConfig.isVisible == false else { return }
      let indexPath = IndexPath(slotIndex: slotIndex, sectionRowCounts: sectionRowCounts)
      viewSlots.insert(slotGenerator(), at: slotIndex.rawValue)
      tableViewChanges.append(indexPath)
      sectionRowCounts[indexPath.section] += 1
    }

    for (presetIndex, preset) in soundFont.presets.enumerated() {
      processPresetConfig(preset.presetConfig) { .preset(index: presetIndex) }
      slotIndex += 1
      for favoriteKey in preset.favorites {
        if let favorite = favorites.getBy(key: favoriteKey) {
          processPresetConfig(favorite.presetConfig) { .favorite(key: favoriteKey) }
          slotIndex += 1
        }
      }
    }

    return tableViewChanges
  }

  /**
   End editing. Removes rows for presets that should be hidden from view. Note that the updates to the section row
   counters is temporary but necessary to keep iOS from throwing an exception due to internal inconsistencies.

   - returns: the list of indices that were removed
   */
  mutating func end() -> [IndexPath] {
    log.debug("end BEGIN")

    var tableViewChanges = [IndexPath]()
    var slotIndex: PresetViewSlotIndex = .init(rawValue: viewSlots.count - 1)

    func processPresetConfig(_ presetConfig: PresetConfig) {
      guard presetConfig.isVisible == false else { return }
      let indexPath = IndexPath(slotIndex: slotIndex, sectionRowCounts: sectionRowCounts)
      viewSlots.remove(at: slotIndex.rawValue)
      tableViewChanges.append(indexPath)
      sectionRowCounts[indexPath.section] -= 1
    }

    while slotIndex.rawValue >= 0 {
      switch viewSlots[slotIndex] {
      case .preset(let index): processPresetConfig(soundFont.presets[index].presetConfig)
      case .favorite(let key):
        if let favorite = favorites.getBy(key: key) {
          processPresetConfig(favorite.presetConfig)
        }
      }
      slotIndex = .init(rawValue: slotIndex.rawValue - 1)
    }

    return tableViewChanges
  }
}
