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

/**
 The index into an array of PresetViewSlot items. Use `Tagged` in order to reduce chance of using wrong index value.
 Otherwise, it is just a 0-based integer index into an array of PresetViewSlot items.
 */
internal typealias PresetViewSlotIndex = Tagged<PresetViewSlot, Int>

extension PresetViewSlotIndex {
  /// Allow adding an integer value to a slot index
  static func + (lhs: PresetViewSlotIndex, rhs: Int) -> PresetViewSlotIndex { Self(rawValue: lhs.rawValue + rhs) }
}

internal extension IndexPath {

  /// The number of items in a section group in the presets table view
  static let sectionSize = 20

  /**
   Create IndexPath from a slot index value with the correct `row` and `section` attributes using the current set of
   section row counters. This is the safest way to calculate an IndexPath as it removes the assumption that each
   section contains `sectionSize` elements: this is not true when preset visibility is being edited.

   - parameter slotIndex: the slot index to work with
   */
  init(slotIndex: PresetViewSlotIndex, sectionRowCounts: [Int]) {
    precondition(!sectionRowCounts.isEmpty)
    var remaining = slotIndex.rawValue
    for (sectionIndex, rowCount) in sectionRowCounts.enumerated() {
      if remaining < rowCount {
        self.init(row: remaining, section: sectionIndex)
        return
      }
      remaining -= rowCount
    }

    self.init(row: remaining, section: sectionRowCounts.count - 1)
  }

  /// Convert from row/section to slot index
  func slotIndex(using sectionRowCounts: [Int]) -> PresetViewSlotIndex {
    .init(rawValue: row + sectionRowCounts[0..<section].reduce(0, +))
  }

  /**
   Obtain section title strings

   - parameter sourceSize: the number of items in the data being shown
   - returns: the array of String values
   */
  static func sectionsTitles(sourceSize: Int) -> [String] {
    stride(from: Self.sectionSize, to: sourceSize - 1, by: Self.sectionSize).map { "\($0)" }
  }
}

internal extension Array where Element == PresetViewSlot {

  /**
   Indexing via PresetViewSlotIndex value.

   - parameter slotIndex: the index to use
   - returns: PresetViewSlot at the given index
   */
  subscript(slotIndex: PresetViewSlotIndex) -> Element { self[slotIndex.rawValue] }

  /**
   Get the index of the first `PresetViewSlot` that holds the given `Favorite.Key` value.

   - parameter key: the key to look for
   - returns: the index of the matching `PresetViewSlot` or nil if none found
   */
  func findFavoriteKey(_ key: Favorite.Key) -> PresetViewSlotIndex? {
    for (index, slot) in self.enumerated() {
      if case let .favorite(slotKey) = slot, slotKey == key {
        return .init(rawValue: index)
      }
    }
    return nil
  }

  /**
   Get the index of the first `PresetViewSlot` that holds the given preset index value.

   - parameter presetIndex: the index to look for
   - returns: the index of the matching `PresetViewSlot` or nil if none found
   */
  func findPresetIndex(_ presetIndex: Int) -> PresetViewSlotIndex? {
    for (index, slot) in self.enumerated() {
      if case let .preset(slotIndex) = slot, slotIndex == presetIndex {
        return .init(rawValue: index)
      }
    }
    return nil
  }

  /**
   Insert a value in the collection at a particular location.

   - parameter value: the value to insert
   - parameter index: the location to insert at
   */
  mutating func insert(_ value: PresetViewSlot, at index: PresetViewSlotIndex) { insert(value, at: index.rawValue) }

  /**
   Remove item from the collection at a particular location.

   - parameter index: the location to remove at
   */
  mutating func remove(at index: PresetViewSlotIndex) { remove(at: index.rawValue) }
}
