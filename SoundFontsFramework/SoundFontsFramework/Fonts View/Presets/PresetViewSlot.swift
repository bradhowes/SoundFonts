// Copyright © 2022 Brad Howes. All rights reserved.

import UIKit.UITableView
import Tagged

/**
 The `PresetTableView` shows the presets of a soundfont as well as any `Favorite` entities that are related to the
 presets. This type represents one entry in the table.
 */
internal enum PresetViewSlot: Equatable {
  case preset(index: Int)
  case favorite(key: Favorite.Key)
}

/// The index into an array of PresetViewSlot items
internal typealias PresetViewSlotIndex = Tagged<PresetViewSlot, Int>

extension PresetViewSlotIndex {
  static func + (lhs: PresetViewSlotIndex, rhs: Int) -> PresetViewSlotIndex {
    Self(rawValue: lhs.rawValue + rhs)
  }
}

internal extension IndexPath {

  static let sectionSize = 20

  init(slotIndex: PresetViewSlotIndex) {
    let section = slotIndex.rawValue / Self.sectionSize
    self.init(row: slotIndex.rawValue - section * Self.sectionSize, section: section)
  }

  var slotIndex: PresetViewSlotIndex { .init(rawValue: section * Self.sectionSize + row) }

  static func sectionsTitles(sourceSize: Int) -> [String] {
    stride(from: Self.sectionSize, to: sourceSize - 1, by: Self.sectionSize).map { "\($0)" }
  }
}

internal extension Array where Element == PresetViewSlot {

  subscript(indexPath: IndexPath) -> Element { self[indexPath.slotIndex] }
  subscript(slotIndex: PresetViewSlotIndex) -> Element { self[slotIndex.rawValue] }

  func findFavoriteKey(_ key: Favorite.Key) -> PresetViewSlotIndex? {
    for (index, slot) in self.enumerated() {
      if case let .favorite(slotKey) = slot, slotKey == key {
        return .init(rawValue: index)
      }
    }
    return nil
  }

  func findPresetIndex(_ presetIndex: Int) -> PresetViewSlotIndex? {
    for (index, slot) in self.enumerated() {
      if case let .preset(slotIndex) = slot, slotIndex == presetIndex {
        return .init(rawValue: index)
      }
    }
    return nil
  }

  mutating func insert(_ value: PresetViewSlot, at slotIndex: IndexPath) {
    self.insert(value, at: slotIndex.slotIndex)
  }

  mutating func insert(_ value: PresetViewSlot, at slotIndex: PresetViewSlotIndex) {
    self.insert(value, at: slotIndex.rawValue)
  }

  mutating func remove(at slotIndex: IndexPath) {
    self.remove(at: slotIndex.slotIndex)
  }

  mutating func remove(at slotIndex: PresetViewSlotIndex) {
    self.remove(at: slotIndex.rawValue)
  }
}
