// Copyright © 2020 Brad Howes. All rights reserved.

import Foundation
import os

/// The event notifications that can come from an ActivePresetManager subscription.
public enum ActivePresetEvent: CustomStringConvertible {

  /**
   Change event

   - Parameter old: the previous active preset
   - Parameter new: the new active preset
   - Parameter playSample: if true, play a note using the new preset
   */
  case change(old: ActivePresetKind, new: ActivePresetKind, playSample: Bool)

  public var description: String {
    switch self {
    case let .change(old, new, _): return "<ActivePresetEvent: change old: \(old) new: \(new)>"
    }
  }
}

/**
 Maintains the active SoundFont preset being used for sound generation. When it changes, it sends an ActivePresetEvent
 event to its subscribers.s
 */
public final class ActivePresetManager: SubscriptionManager<ActivePresetEvent>, Tasking {
  private lazy var log = Logging.logger("ActivePresetManager")
  private let soundFonts: SoundFonts
  private let favorites: Favorites
  private let selectedSoundFontManager: SelectedSoundFontManager
  private let settings: Settings
  private var pending: ActivePresetKind = .none

  /// The currently active preset (if any)
  public private(set) var active: ActivePresetKind

  /// The currently active sound font (if any)
  public var activeSoundFont: SoundFont? {
    guard let key = active.soundFontAndPreset?.soundFontKey else { return nil }
    return soundFonts.getBy(key: key)
  }

  /// The currently active preset instance (if any)
  public var activePreset: Preset? {
    guard let soundFontAndPreset = active.soundFontAndPreset,
          let soundFont = soundFonts.getBy(key: soundFontAndPreset.soundFontKey)
    else {
      return nil
    }
    return soundFont[soundFontAndPreset]
  }

  /// The currently active preset instance (if any)
  public var activeFavorite: Favorite? { active.favorite }

  /// The preset configuration for the currently active preset or favorite
  public var activePresetConfig: PresetConfig? {
    activeFavorite?.presetConfig ?? activePreset?.presetConfig
  }

  /**
   Construct new manager

   - parameter soundFont: the sound font manager
   - parameter selectedSoundFontManager: the manager of the selected sound font
   - parameter inApp: true if the running inside the app, false if running in the AUv3 extension
   */
  public init(soundFonts: SoundFonts, favorites: Favorites, selectedSoundFontManager: SelectedSoundFontManager,
              settings: Settings) {
    self.active = .none
    self.soundFonts = soundFonts
    self.favorites = favorites
    self.selectedSoundFontManager = selectedSoundFontManager
    self.settings = settings

    super.init()
    os_log(.info, log: log, "init")

    soundFonts.subscribe(self, notifier: soundFontsChanged_BT)
    favorites.subscribe(self, notifier: favoritesChanged_BT)
  }

  /**
   Obtain the sound font instance that corresponds to the given preset key.

   - parameter soundFontAndPreset: the preset key to resolve
   - returns: optional sound font instance that corresponds to the given key
   */
  public func resolveToSoundFont(_ soundFontAndPreset: SoundFontAndPreset) -> SoundFont? {
    soundFonts.getBy(key: soundFontAndPreset.soundFontKey)
  }

  /**
   Obtain the preset instance that corresponds to the given preset key.

   - parameter soundFontAndPreset: the preset key to resolve
   - returns: optional patch instance that corresponds to the given key
   */
  public func resolveToPreset(_ soundFontAndPreset: SoundFontAndPreset) -> Preset? {
    soundFonts.getBy(key: soundFontAndPreset.soundFontKey)?.presets[soundFontAndPreset.presetIndex]
  }

  /**
   Set a new active preset.

   - parameter preset: the preset to make active
   - parameter playSample: if true, play a note using the new preset
   */
  public func setActive(preset: SoundFontAndPreset, playSample: Bool) {
    setActive(.preset(soundFontAndPreset: preset), playSample: playSample)
  }

  /**
   Make a favorite the active preset.

   - parameter favorite: the favorite to make active
   - parameter playSample: if true, play a note using the new preset
   */
  public func setActive(favorite: Favorite, playSample: Bool) {
    setActive(.favorite(favorite: favorite), playSample: playSample)
  }

  /**
   Set a new active value.

   - parameter kind: wrapped value to set
   - parameter playSample: if true, play a note using the new preset
   */
  public func setActive(_ kind: ActivePresetKind, playSample: Bool = false) {
    os_log(.debug, log: log, "setActive BEGIN - %{public}s", kind.description)

    guard soundFonts.restored && favorites.restored && pending == .none else {
      os_log(.debug, log: log, "setActive END - not restored")
      return
    }

    guard active != kind else {
      os_log(.debug, log: log, "setActive END - preset already active")
      return
    }

    let old = active
    active = kind
    save(kind)
    notify(.change(old: old, new: kind, playSample: playSample))
  }

  /**
   Restore an active value.

   - parameter kind: wrapped value to set
   */
  public func restoreActive(_ kind: ActivePresetKind) {
    os_log(.debug, log: log, "restoreActive BEGIN - %{public}s", kind.description)
    pending = kind
    notifyPending()
  }

  private func notifyPending() {
    os_log(.info, log: log, "notifyFirstActive BEGIN")
    guard soundFonts.restored && favorites.restored && pending != .none else {
      return
    }
    let kind = pending
    pending = .none
    setActive(rebuild(kind), playSample: false)
    pending = .none
  }

  private func rebuild(_ kind: ActivePresetKind) -> ActivePresetKind {
    switch kind {
    case .preset: return kind
    case .favorite(let favorite):
      if favorites.contains(key: favorite.key) {
        return .favorite(favorite: favorites.getBy(key: favorite.key))
      } else if let preset = soundFonts.defaultPreset {
        return .preset(soundFontAndPreset: preset)
      } else {
        return .none
      }
    case .none: return .none
    }
  }
}

extension ActivePresetManager {

  private func favoritesChanged_BT(_ event: FavoritesEvent) {
    if case .restored = event {
      Self.onMain { self.notifyPending() }
    }
  }

  private func soundFontsChanged_BT(_ event: SoundFontsEvent) {
    if case .restored = event {
      Self.onMain { self.notifyPending() }
    }
  }

  private func save(_ kind: ActivePresetKind) {
    os_log(.info, log: log, "save - %{public}s", kind.description)
    settings.lastActivePreset = kind
  }

  private func isValid(_ active: ActivePresetKind) -> Bool {
    precondition(soundFonts.restored)
    guard let soundFontAndPreset = active.soundFontAndPreset else { return false }
    return soundFonts.resolve(soundFontAndPreset: soundFontAndPreset) != nil
  }
}
