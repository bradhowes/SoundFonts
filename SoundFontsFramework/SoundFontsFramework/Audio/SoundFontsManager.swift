// Copyright © 2019 Brad Howes. All rights reserved.

import SF2Files
import SoundFontInfoLib
import UIKit
import os

/// Manages a collection of SoundFont instances. Changes to the collection are communicated as SoundFontsEvent events.
public final class SoundFontsManager: SubscriptionManager<SoundFontsEvent> {
  private static let log: Logger = Logging.logger("SoundFontsManager")
  private var log: Logger { Self.log }
  private let settings: Settings

  private var observer: ConsolidatedConfigObserver!
  public var collection: SoundFontCollection? { observer?.soundFonts }

  private var bookmarkChangeObserver: NSObjectProtocol?

  /**
   Create a new manager for a collection of SoundFonts. Attempts to load from disk a saved collection, and if that
   fails then creates a new one containing SoundFont instances embedded in the app.
   */
  public init(_ consolidatedConfigProvider: ConsolidatedConfigProvider, settings: Settings) {
    self.settings = settings
    super.init()
    self.observer = ConsolidatedConfigObserver(configProvider: consolidatedConfigProvider) { [weak self] in
      guard let self else { return }
      self.notifyCollectionRestored()
    }

    bookmarkChangeObserver = NotificationCenter.default.addObserver(forName: .bookmarkChanged, object: nil,
                                                                    queue: nil) { [weak self] _ in
      guard let self else { return }
      if self.observer.isRestored {
        self.markCollectionChanged()
      }
    }
  }
}

extension FileManager {

  fileprivate var installedSF2Files: [URL] { FileManager.default.sharedPaths }

  fileprivate func validateSF2Files(log: Logger, collection: SoundFontCollection) -> Int {
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
      log.debug("removing '\(destination.path, privacy: .public)' if it exists")

      try? removeItem(at: destination)
      log.debug("copying '\(source.path, privacy: .public)' to '\(destination.path, privacy: .public)'")

      do {
        try copyItem(at: source, to: destination)
      } catch let error as NSError {
        log.error("\(error.localizedDescription)")
      }

      log.debug("removing '\(source.path)'")
      try? removeItem(at: source)
      found += 1
    }

    return found
  }
}

// MARK: - SoundFonts Protocol

extension SoundFontsManager: SoundFontsProvider {

  public var isRestored: Bool { observer.isRestored }

  public var count: Int { collection?.count ?? 0 }

  public var isEmpty: Bool { collection?.isEmpty ?? true }

  public var soundFontNames: [String] { collection?.soundFonts.map { $0.displayName } ?? [] }

  public var defaultPreset: SoundFontAndPreset? { collection?.defaultPreset }

  public func firstIndex(of key: SoundFont.Key) -> Int? { collection?.firstIndex(of: key) }

  public func getBy(index: Int) -> SoundFont? { collection?.getBy(index: index) }

  public func getBy(key: SoundFont.Key) -> SoundFont? { collection?.getBy(key: key) }

  public func getBy(soundFontAndPreset: SoundFontAndPreset) -> SoundFont? {
    collection?.getBy(soundFontAndPreset: soundFontAndPreset)
  }

  public func validateCollections(favorites: FavoritesProvider, tags: TagsProvider) {
    guard let collection else { fatalError("logic error -- nil collection") }
    log.debug("validateCollections")
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
    guard let collection else { fatalError("logic error -- nil collection") }
    let soundFont = collection.getBy(soundFontAndPreset: soundFontAndPreset)
    return soundFont?.presets[soundFontAndPreset.presetIndex]
  }

  public func filtered(by tag: Tag.Key) -> [SoundFont.Key] {
    guard let collection else { fatalError("logic error -- nil collection") }
    return collection.soundFonts.filter { soundFont in
      soundFont.tags.union(soundFont.kind.builtin ? Tag.stockTagSet : Tag.allTagSet)
        .contains(tag)
    }.map { $0.key }
  }

  public func indexFilteredByTag(index: Int, tag: Tag.Key) -> Int {
    guard let collection else { fatalError("logic error -- nil collection") }
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
    guard let collection else { fatalError("logic error -- nil collection") }
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
    guard let collection else { fatalError("logic error -- nil collection") }
    guard let index = collection.firstIndex(of: key) else { return }
    guard let soundFont = collection.remove(index) else { return }
    defer { markCollectionChanged() }
    notify(.removed(old: index, font: soundFont))
  }

  public func rename(key: SoundFont.Key, name: String) {
    guard let collection else { fatalError("logic error -- nil collection") }
    guard let index = collection.firstIndex(of: key) else { return }
    defer { markCollectionChanged() }
    let (newIndex, soundFont) = collection.rename(index, name: name)
    if let soundFont {
      notify(.moved(old: index, new: newIndex, font: soundFont))
    }
  }

  public func removeTag(_ tag: Tag.Key) {
    guard let collection else { fatalError("logic error -- nil collection") }
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
    log.debug("updatePreset - \(preset.originalName) \(config.name)")
    preset.presetConfig = config
    notify(.presetChanged(font: soundFont, index: soundFontAndPreset.presetIndex))
  }

  public func setVisibility(soundFontAndPreset: SoundFontAndPreset, state isVisible: Bool) {
    guard let soundFont = getBy(key: soundFontAndPreset.soundFontKey) else { return }
    defer { markCollectionChanged() }
    let preset = soundFont.presets[soundFontAndPreset.presetIndex]
    preset.presetConfig.isHidden = !isVisible
  }

  public func setEffects(soundFontAndPreset: SoundFontAndPreset, delay: DelayConfig?, reverb: ReverbConfig?) {
    guard let soundFont = getBy(key: soundFontAndPreset.soundFontKey) else { return }
    defer { markCollectionChanged() }
    let preset = soundFont.presets[soundFontAndPreset.presetIndex]
    preset.presetConfig.delayConfig = delay
    preset.presetConfig.reverbConfig = reverb
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
    guard let collection else { fatalError("logic error -- nil collection") }
    let urls = SF2Files.allResources
    let found = urls.first { collection.index(of: $0) != nil }
    return found != nil
  }

  public var hasAllBundled: Bool {
    guard let collection else { fatalError("logic error -- nil collection") }
    let urls = SF2Files.allResources
    let found = urls.filter { collection.index(of: $0) != nil }
    return found.count == urls.count
  }

  public func removeBundled() {
    guard let collection else { fatalError("logic error -- nil collection") }
    log.debug("removeBundled")
    defer { markCollectionChanged() }
    for url in SF2Files.allResources {
      if let index = collection.index(of: url) {
        log.debug("removing \(url.absoluteString)")
        guard let soundFont = collection.remove(index) else { return }
        notify(.removed(old: index, font: soundFont))
      }
    }
  }

  public func restoreBundled() {
    guard let collection else { fatalError("logic error -- nil collection") }
    log.debug("restoreBundled")
    defer { markCollectionChanged() }
    for url in SF2Files.allResources where collection.index(of: url) == nil {
      log.debug("restoring \(url.absoluteString)")
      if let soundFont = Self.addFromBundle(url: url) {
        let index = collection.add(soundFont)
        notify(.added(new: index, font: soundFont))
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
      try? fm.removeItem(at: destination)
      try fm.copyItem(at: source, to: destination)
      return true
    } catch let error as NSError {
      log.error("\(error.localizedDescription, privacy: .public)")
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
        try? fm.removeItem(at: destination)
        try fm.copyItem(at: source, to: destination)
        good += 1
      } catch {
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
    guard let collection else { fatalError("logic error -- nil collection") }
    log.info("markCollectionChanged - \(collection.description, privacy: .public)")
    observer.markAsChanged()
  }

  private func notifyCollectionRestored() {
    log.debug("restored")
    notify(.restored)
  }
}
