//
//  PresetsTableRowVisibilityEditor.swift
// Copyright © 2022 Brad Howes. All rights reserved.

import Foundation
import os.log

internal struct PresetsTableRowVisibilityEditor {
  private let log = Logging.logger("PresetsTableRowVisibilityEditor")
  private(set) var viewSlots: [PresetViewSlot]
  private(set) var sectionRowCounts: [Int]
  private let soundFont: SoundFont
  private let favorites: Favorites

  init(viewSlots: [PresetViewSlot], sectionRowCounts: [Int], soundFont: SoundFont, favorites: Favorites) {
    self.viewSlots = viewSlots
    self.sectionRowCounts = sectionRowCounts
    self.soundFont = soundFont
    self.favorites = favorites
  }

  mutating func begin() -> [IndexPath] {
    os_log(.debug, log: log, "begin BEGIN")
    var tableViewChanges = [IndexPath]()
    var slotIndex: PresetViewSlotIndex = 0

    func processPresetConfig(_ presetConfig: PresetConfig, slotGenerator: () -> PresetViewSlot) {
      guard presetConfig.isVisible == false else { return }
      let indexPath = IndexPath(slotIndex: slotIndex)
      os_log(.info, log: log, "calculateVisibilityRowChanges - showing slot %d [%d.%d] '%{public}s'",
             slotIndex.rawValue, indexPath.section, indexPath.row, presetConfig.name)

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

  mutating func end() -> [IndexPath] {
    os_log(.debug, log: log, "end BEGIN")

    var tableViewChanges = [IndexPath]()
    var slotIndex: PresetViewSlotIndex = .init(rawValue: viewSlots.count - 1)

    func processPresetConfig(_ presetConfig: PresetConfig) {
      guard presetConfig.isVisible == false else { return }
      let indexPath = IndexPath(slotIndex: slotIndex, sectionRowCounts: sectionRowCounts)
      os_log(.info, log: log, "calculateVisibilityRowChanges - hiding slot %d [%d.%d] '%{public}s'",
             slotIndex.rawValue, indexPath.section, indexPath.row, presetConfig.name)
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
