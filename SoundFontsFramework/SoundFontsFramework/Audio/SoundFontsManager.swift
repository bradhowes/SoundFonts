// Copyright © 2019 Brad Howes. All rights reserved.

import SF2Files
import SoundFontInfoLib
import UIKit
import os

/// Manages a collection of SoundFont instances. Changes to the collection are communicated as a SoundFontsEvent event.
public final class SoundFontsManager: SubscriptionManager<SoundFontsEvent> {
  private static let log = Logging.logger("SoundFontsManager")
  private var log: OSLog { Self.log }
  private let settings: Settings

  private var observer: ConsolidatedConfigFileObserver!
  public var collection: SoundFontCollection { observer.soundFonts }

  /**
   Create a new manager for a collection of SoundFonts. Attempts to load from disk a saved collection, and if that
   fails then creates a new one containing SoundFont instances embedded in the app.
   */
  public init(_ consolidatedConfigProvider: ConsolidatedConfigProvider, settings: Settings) {
    self.settings = settings
    super.init()
    observer = ConsolidatedConfigFileObserver(configProvider: consolidatedConfigProvider, restored: notifyCollectionRestored)
  }
}

extension FileManager {

  fileprivate var installedSF2Files: [URL] {
    let fileNames = FileManager.default.sharedFileNames
    return fileNames.map { FileManager.default.sharedPath(for: $0) }
  }

  fileprivate func validateSF2Files(log: OSLog, collection: SoundFontCollection) -> Int {
    guard let contents = try? contentsOfDirectory(atPath: sharedDocumentsDirectory.path) else {
      return -1
    }

    var found = 0
    for path in contents {
      let source = sharedDocumentsDirectory.appendingPathComponent(path)
      guard source.pathExtension == SF2Files.sf2Extension else { continue }

      let (stripped, uuid) = path.stripEmbeddedUUID()
      if let uuid = uuid, collection.getBy(key: uuid) != nil { continue }

      let destination = localDocumentsDirectory.appendingPathComponent(stripped)
      os_log(.info, log: log, "removing '%{public}s' if it exists", destination.path)

      try? removeItem(at: destination)
      os_log(.info, log: log, "copying '%{public}s' to '%{public}s'", source.path, destination.path)

      do {
        try copyItem(at: source, to: destination)
      } catch let error as NSError {
        os_log(.error, log: log, "%{public}s", error.localizedDescription)
      }

      os_log(.info, log: log, "removing '%{public}s'", source.path)
      try? removeItem(at: source)
      found += 1
    }

    return found
  }
}

// MARK: - SoundFonts Protocol

extension SoundFontsManager: SoundFonts {

  public var isRestored: Bool { observer.isRestored }

  public var count: Int { return collection.count }

  public var soundFontNames: [String] { collection.soundFonts.map { $0.displayName } }

  public var defaultPreset: SoundFontAndPreset? { collection.defaultPreset }

  public func firstIndex(of key: SoundFont.Key) -> Int? { collection.firstIndex(of: key) }

  public func getBy(index: Int) -> SoundFont { collection.getBy(index: index) }

  public func getBy(key: SoundFont.Key) -> SoundFont? { collection.getBy(key: key) }

  public func getBy(soundFontAndPreset: SoundFontAndPreset) -> SoundFont? {
    collection.getBy(soundFontAndPreset: soundFontAndPreset)
  }

  public func validateCollections(favorites: Favorites, tags: Tags) {
    os_log(.info, log: log, "validateCollections")
    favorites.validate(self)
    tags.validate()
    for soundFont in collection.soundFonts {
      for preset in soundFont.presets {
        preset.validate(favorites)
      }
      soundFont.validate(tags)
    }
  }

  public func resolve(soundFontAndPreset: SoundFontAndPreset) -> Preset? {
    let soundFont = collection.getBy(soundFontAndPreset: soundFontAndPreset)
    return soundFont?.presets[soundFontAndPreset.presetIndex]
  }

  public func filtered(by tag: Tag.Key) -> [SoundFont.Key] {
    collection.soundFonts.filter { soundFont in
      soundFont.tags.union(soundFont.kind.resource ? Tag.stockTagSet : Tag.allTagSet)
        .contains(tag)
    }.map { $0.key }
  }

  public func filteredIndex(index: Int, tag: Tag.Key) -> Int {
    var reduction = 0
    for entry in collection.soundFonts.enumerated()
    where entry.offset <= index && !entry.element.tags.union(Tag.allTagSet).contains(tag) {
      reduction += 1
    }

    return index - reduction
  }

  public func names(of keys: [SoundFont.Key]) -> [String] {
    keys.compactMap { getBy(key: $0)?.displayName }
  }

  @discardableResult
  public func add(url: URL) -> Result<(Int, SoundFont), SoundFontFileLoadFailure> {
    switch SoundFont.makeSoundFont(from: url, copyFilesWhenAdding: settings.copyFilesWhenAdding) {
    case .failure(let failure): return .failure(failure)
    case .success(let soundFont):
      defer { markCollectionChanged() }
      let index = collection.add(soundFont)
      notify(.added(new: index, font: soundFont))
      return .success((index, soundFont))
    }
  }

  public func remove(key: SoundFont.Key) {
    guard let index = collection.firstIndex(of: key) else { return }
    guard let soundFont = collection.remove(index) else { return }
    defer { markCollectionChanged() }
    notify(.removed(old: index, font: soundFont))
  }

  public func rename(key: SoundFont.Key, name: String) {
    guard let index = collection.firstIndex(of: key) else { return }
    defer { markCollectionChanged() }
    let (newIndex, soundFont) = collection.rename(index, name: name)
    notify(.moved(old: index, new: newIndex, font: soundFont))
  }

  public func removeTag(_ tag: Tag.Key) {
    defer { markCollectionChanged() }
    for soundFont in collection.soundFonts {
      var tags = soundFont.tags
      tags.remove(tag)
      soundFont.tags = tags
    }
  }

  public func createFavorite(soundFontAndPreset: SoundFontAndPreset, keyboardLowestNote: Note?) -> Favorite? {
    guard let soundFont = getBy(key: soundFontAndPreset.soundFontKey) else { return nil }
    defer { markCollectionChanged() }
    let preset = soundFont.presets[soundFontAndPreset.presetIndex]
    return preset.makeFavorite(soundFontAndPreset: soundFontAndPreset, keyboardLowestNote: keyboardLowestNote)
  }

  public func deleteFavorite(soundFontAndPreset: SoundFontAndPreset, key: Favorite.Key) {
    guard let soundFont = getBy(key: soundFontAndPreset.soundFontKey) else { return }
    defer { markCollectionChanged() }
    let preset = soundFont.presets[soundFontAndPreset.presetIndex]
    preset.favorites.removeAll { $0 == key }
  }

  public func updatePreset(soundFontAndPreset: SoundFontAndPreset, config: PresetConfig) {
    guard let soundFont = getBy(key: soundFontAndPreset.soundFontKey) else { return }
    defer { markCollectionChanged() }
    let preset = soundFont.presets[soundFontAndPreset.presetIndex]
    os_log(.info, log: log, "updatePreset - %{public}s %{public}s", preset.originalName, config.name)
    preset.presetConfig = config
    notify(.presetChanged(font: soundFont, index: soundFontAndPreset.presetIndex))
  }

  public func setVisibility(soundFontAndPreset: SoundFontAndPreset, state isVisible: Bool) {
    guard let soundFont = getBy(key: soundFontAndPreset.soundFontKey) else { return }
    defer { markCollectionChanged() }
    let preset = soundFont.presets[soundFontAndPreset.presetIndex]
    os_log(.debug, log: log, "setVisibility - %{public}s %d - %d", soundFontAndPreset.soundFontKey.uuidString,
           soundFontAndPreset.presetIndex, isVisible)
    preset.presetConfig.isHidden = !isVisible
  }

  public func setEffects(soundFontAndPreset: SoundFontAndPreset, delay: DelayConfig?, reverb: ReverbConfig?,
                         chorus: ChorusConfig?) {
    guard let soundFont = getBy(key: soundFontAndPreset.soundFontKey) else { return }
    os_log(.debug, log: log, "setEffects - %{public}s %d %{public}s %{public}s",
           soundFontAndPreset.soundFontKey.uuidString, soundFontAndPreset.presetIndex,
           delay?.description ?? "nil", reverb?.description ?? "nil", chorus?.description ?? "nil")
    defer { markCollectionChanged() }
    let preset = soundFont.presets[soundFontAndPreset.presetIndex]
    preset.presetConfig.delayConfig = delay
    preset.presetConfig.reverbConfig = reverb
    preset.presetConfig.chorusConfig = chorus
  }

  public func makeAllVisible(key: SoundFont.Key) {
    guard let soundFont = getBy(key: key) else { return }
    defer { markCollectionChanged() }
    for preset in soundFont.presets where preset.presetConfig.isHidden == true {
      preset.presetConfig.isHidden = false
    }
    notify(.unhidPresets(font: soundFont))
  }

  public var hasAnyBundled: Bool {
    let urls = SF2Files.allResources
    let found = urls.first { collection.index(of: $0) != nil }
    return found != nil
  }

  public var hasAllBundled: Bool {
    let urls = SF2Files.allResources
    let found = urls.filter { collection.index(of: $0) != nil }
    return found.count == urls.count
  }

  public func removeBundled() {
    os_log(.info, log: log, "removeBundled")
    defer { markCollectionChanged() }
    for url in SF2Files.allResources {
      if let index = collection.index(of: url) {
        os_log(.info, log: log, "removing %{public}s", url.absoluteString)
        guard let soundFont = collection.remove(index) else { return }
        notify(.removed(old: index, font: soundFont))
      }
    }
  }

  public func restoreBundled() {
    os_log(.info, log: log, "restoreBundled")
    defer { markCollectionChanged() }
    for url in SF2Files.allResources {
      if collection.index(of: url) == nil {
        os_log(.info, log: log, "restoring %{public}s", url.absoluteString)
        if let soundFont = Self.addFromBundle(url: url) {
          let index = collection.add(soundFont)
          notify(.added(new: index, font: soundFont))
        }
      }
    }
  }

  public func reloadEmbeddedInfo(key: SoundFont.Key) {
    guard let soundFont = getBy(key: key) else { return }
    guard
      soundFont.embeddedAuthor.isEmpty && soundFont.embeddedComment.isEmpty
        && soundFont.embeddedCopyright.isEmpty
    else {
      return
    }

    if soundFont.reloadEmbeddedInfo() {
      markCollectionChanged()
    }
  }

  /**
   Copy one file to the local document directory.
   */
  public func copyToLocalDocumentsDirectory(name: String) -> Bool {
    let fm = FileManager.default
    let source = fm.sharedDocumentsDirectory.appendingPathComponent(name)
    let destination = fm.localDocumentsDirectory.appendingPathComponent(name)
    do {
      os_log(.info, log: Self.log, "removing '%{public}s' if it exists", destination.path)
      try? fm.removeItem(at: destination)
      os_log(
        .info, log: Self.log, "copying '%{public}s' to '%{public}s'", source.path, destination.path)
      try fm.copyItem(at: source, to: destination)
      return true
    } catch let error as NSError {
      os_log(.error, log: Self.log, "%{public}s", error.localizedDescription)
    }
    return false
  }

  /**
   Copy all of the known SF2 files to the local document directory.
   */
  public func exportToLocalDocumentsDirectory() -> (good: Int, total: Int) {
    let fm = FileManager.default
    guard let contents = try? fm.contentsOfDirectory(atPath: fm.sharedDocumentsDirectory.path)
    else {
      return (good: 0, total: 0)
    }

    var good = 0
    var bad = 0
    for path in contents {
      let source = fm.sharedDocumentsDirectory.appendingPathComponent(path)
      guard let attributes = try? fm.attributesOfItem(atPath: source.path) else { continue }
      guard let fileType = attributes[.type] as? String else { continue }
      guard fileType == "NSFileTypeRegular" else { continue }
      let (stripped, _) = path.stripEmbeddedUUID()
      guard stripped.first != "." else { continue }

      let destination = fm.localDocumentsDirectory.appendingPathComponent(stripped)
      do {
        os_log(.info, log: Self.log, "removing '%{public}s' if it exists", destination.path)
        try? fm.removeItem(at: destination)
        os_log(
          .info, log: Self.log, "copying '%{public}s' to '%{public}s'", source.path,
          destination.path)
        try fm.copyItem(at: source, to: destination)
        good += 1
      } catch let error as NSError {
        os_log(.error, log: Self.log, "%{public}s", error.localizedDescription)
        bad += 1
      }
    }
    return (good: good, total: good + bad)
  }

  /**
   Import all SF2 files from the local documents directory that is visible to the user.
   */
  public func importFromLocalDocumentsDirectory() -> (good: Int, total: Int) {
    let fm = FileManager.default
    guard let contents = try? fm.contentsOfDirectory(atPath: fm.localDocumentsDirectory.path) else {
      return (good: 0, total: 0)
    }

    var good = 0
    var bad = 0
    for path in contents {
      guard path.hasSuffix(SF2Files.sf2DottedExtension) else { continue }
      let src = fm.localDocumentsDirectory.appendingPathComponent(path)
      switch add(url: src) {
      case .success: good += 1
      case .failure: bad += 1
      }
    }

    return (good: good, total: good + bad)
  }
}

extension SoundFontsManager {

  private static let niceNames = [
    "Fluid": "Fluid R3", "Free Font": "FreeFont", "GeneralUser": "MuseScore", "User": "Roland"
  ]

  @discardableResult
  fileprivate static func addFromBundle(url: URL) -> SoundFont? {
    guard let info = SoundFontInfo.load(viaParser: url) else { return nil }
    guard let infoName = info.embeddedName else { return nil }
    guard !(infoName.isEmpty || info.presets.isEmpty) else { return nil }
    let displayName =
      niceNames.first { (key, _) in info.embeddedName.hasPrefix(key) }?.value ?? infoName
    return SoundFont(displayName, soundFontInfo: info, resource: url)
  }

  @discardableResult
  fileprivate static func addFromSharedFolder(url: URL, copyFilesWhenAdding: Bool) -> SoundFont? {
    switch SoundFont.makeSoundFont(from: url, copyFilesWhenAdding: copyFilesWhenAdding) {
    case .success(let soundFont): return soundFont
    case .failure: return nil
    }
  }
}

extension SoundFontsManager {

  static var defaultCollection: SoundFontCollection {
    let bundleUrls: [URL] = SF2Files.allResources
    let fileUrls = FileManager.default.installedSF2Files
    return .init(soundFonts: (bundleUrls.compactMap { addFromBundle(url: $0) })
                 + (fileUrls.compactMap { addFromSharedFolder(url: $0, copyFilesWhenAdding: true) }))
  }

  /**
   Mark the current configuration as dirty so that it will get saved.
   */
  private func markCollectionChanged() {
    os_log(.info, log: log, "markCollectionChanged - %{public}@", collection.description)
    observer.markAsChanged()
  }

  private func notifyCollectionRestored() {
    os_log(.info, log: log, "restored")
    notify(.restored)
  }
}
