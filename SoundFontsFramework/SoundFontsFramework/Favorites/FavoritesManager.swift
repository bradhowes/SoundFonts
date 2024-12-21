// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import os.log

/**
 Manages the collection of Favorite instances created by the user. Changes to the collection are saved, and they
 will be restored when the app relaunches.
 */
final class FavoritesManager: SubscriptionManager<FavoritesEvent> {
  private lazy var log: Logger = Logging.logger("FavoritesManager")

  private var observer: ConsolidatedConfigObserver!
  private var collection: FavoriteCollection? { observer.favorites }

  init(_ consolidatedConfigProvider: ConsolidatedConfigProvider) {
    super.init()
    observer = ConsolidatedConfigObserver(configProvider: consolidatedConfigProvider) { [weak self] in
      guard let self else { return }
      self.notifyCollectionRestored()
    }
  }
}

// MARK: - Favorites protocol

extension FavoritesManager: FavoritesProvider {

  var isRestored: Bool { observer.isRestored }

  var count: Int { collection? .count ?? 0 }

  func contains(key: Favorite.Key) -> Bool { collection?.contains(key: key) ?? false }

  func index(of key: Favorite.Key) -> Int? { collection?.index(of: key) }

  func getBy(index: Int) -> Favorite? { collection?.getBy(index: index) }

  func getBy(key: Favorite.Key) -> Favorite? { collection?.getBy(key: key) }

  func add(favorite: Favorite) {
    guard let collection else { fatalError("logic error -- nil collection") }
    defer { markCollectionChanged() }
    collection.add(favorite: favorite)
    notify(.added(index: count - 1, favorite: favorite))
  }

  func update(index: Int, config: PresetConfig) {
    guard let collection else { fatalError("logic error -- nil collection") }
    defer { markCollectionChanged() }
    let favorite = collection.getBy(index: index)
    favorite.presetConfig = config
    collection.replace(index: index, with: favorite)
    notify(.changed(index: index, favorite: favorite))
  }

  func beginEdit(config: FavoriteEditor.Config) {
    notify(.beginEdit(config: config))
  }

  func move(from: Int, to: Int) {
    guard let collection else { fatalError("logic error -- nil collection") }
    defer { markCollectionChanged() }
    collection.move(from: from, to: to)
  }

  func selected(index: Int) {
    guard let collection else { fatalError("logic error -- nil collection") }
    notify(.selected(index: index, favorite: collection.getBy(index: index)))
  }

  func remove(key: Favorite.Key) {
    guard let collection else { fatalError("logic error -- nil collection") }
    guard let index = collection.index(of: key) else { return }
    let favorite = collection.remove(at: index)
    notify(.removed(index: index, favorite: favorite))
    markCollectionChanged()
  }

  func removeAll(associatedWith soundFont: SoundFont) {
    guard let collection else { fatalError("logic error -- nil collection") }
    collection.removeAll(associatedWith: soundFont.key)
    notify(.removedAll(associatedWith: soundFont))
    markCollectionChanged()
  }

  func count(associatedWith soundFont: SoundFont) -> Int {
    guard let collection else { fatalError("logic error -- nil collection") }
    return collection.count(associatedWith: soundFont.key)
  }

  func setVisibility(key: Favorite.Key, state isVisible: Bool) {
    guard let collection else { fatalError("logic error -- nil collection") }
    if let favorite = collection.getBy(key: key) {
      favorite.presetConfig.isHidden = !isVisible
      markCollectionChanged()
    }
  }

  func setEffects(favorite: Favorite, delay: DelayConfig?, reverb: ReverbConfig?) {
    defer { markCollectionChanged() }
    favorite.presetConfig.delayConfig = delay
    favorite.presetConfig.reverbConfig = reverb
  }

  func validate(_ soundFonts: SoundFontsProvider) {
    var invalidFavoriteKeys = [Favorite.Key]()
    for index in 0..<self.count {
      if let favorite = self.getBy(index: index) {
        if let preset = soundFonts.resolve(soundFontAndPreset: favorite.soundFontAndPreset) {
          if !preset.favorites.contains(favorite.key) {
            log.error("linking favorite - '\(favorite.presetConfig.name, privacy: .public)'")
            preset.favorites.append(favorite.key)
          }
        } else {
          log.error("found orphan favorite - '\(favorite.presetConfig.name, privacy: .public)'")
          invalidFavoriteKeys.append(favorite.key)
        }
      } else {
        log.error("encountered nil favorite at index \(index)")
      }
    }
    for key in invalidFavoriteKeys {
      self.remove(key: key)
    }
  }
}

extension FavoritesManager {

  static var defaultCollection: FavoriteCollection { FavoriteCollection() }

  private func markCollectionChanged() {
    guard let collection else { fatalError("logic error -- nil collection") }
    log.info("markCollectionChanged - \(collection.description, privacy: .public)")
    observer.markAsChanged()
  }

  private func notifyCollectionRestored() {
    log.debug("notifyCollectionRestored")
    notify(.restored)
  }
}
