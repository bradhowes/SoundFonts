// Copyright © 2020 Brad Howes. All rights reserved.

import Foundation
import os

/// The event notifications that can come from an ActivePresetManager subscription.
public enum ActivePresetEvent {

  /**
   Change event

   - Parameter old: the previous active preset
   - Parameter new: the new active preset
   - Parameter playSample: if true, play a note using the new preset
   */
  case active(old: ActivePresetKind, new: ActivePresetKind, playSample: Bool)
}

/// Maintains the active SoundFont preset being used for sound generation. There should only ever be one instance of this
/// class, but this is not enforced.
public final class ActivePresetManager: SubscriptionManager<ActivePresetEvent> {
  private lazy var log = Logging.logger("ActivePresetManager")
  private let soundFonts: SoundFonts
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
  public init(soundFonts: SoundFonts, selectedSoundFontManager: SelectedSoundFontManager, settings: Settings) {
    self.active = .none
    self.soundFonts = soundFonts
    self.selectedSoundFontManager = selectedSoundFontManager
    self.settings = settings

    super.init()
    os_log(.info, log: log, "init")
    soundFonts.subscribe(self, notifier: soundFontsChange)
    os_log(.info, log: log, "active: %{public}s", active.description)
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
  @discardableResult
  public func setActive(preset: SoundFontAndPreset, playSample: Bool) -> Bool {
    setActive(.preset(soundFontAndPreset: preset), playSample: playSample)
  }

  /**
   Make a favorite the active preset.

   - parameter favorite: the favorite to make active
   - parameter playSample: if true, play a note using the new preset
   */
  @discardableResult
  public func setActive(favorite: Favorite, playSample: Bool) -> Bool {
    setActive(.favorite(favorite: favorite), playSample: playSample)
  }

  /**
   Set a new active value.

   - parameter kind: wrapped value to set
   - parameter playSample: if true, play a note using the new preset
   */
  @discardableResult
  public func setActive(_ kind: ActivePresetKind, playSample: Bool = false) -> Bool {
    os_log(.debug, log: log, "setActive: %{public}s", kind.description)
    guard soundFonts.restored else {

      // NOTE: this could be the case for AUv3 where the audio unit is up and running and has restored a
      // configuration but we don't have everything else restored just yet.
      os_log(
        .info, log: log, "not yet restored - setting pending - current: %{public}s",
        kind.description)
      if pending == .none {
        pending = kind
      }
      return true
    }

    guard active != kind else {
      os_log(.debug, log: log, "already active")
      return false
    }

    let old = active
    active = kind
    save(kind)
    DispatchQueue.main.async { self.notify(.active(old: old, new: kind, playSample: playSample)) }

    return true
  }
}

extension ActivePresetManager {

  private func soundFontsChange(_ event: SoundFontsEvent) {

    // We only care about restoration event
    guard case .restored = event else { return }
    os_log(.info, log: log, "SF collection restored")

    if pending != .none {
      os_log(.info, log: log, "using pending value")
      setActive(pending, playSample: false)
    } else {
      let restored = settings.lastActivePreset
      if isValid(restored) {
        os_log(.info, log: log, "using restored value from UserDefaults")
        setActive(restored, playSample: false)
      } else if let defaultPreset = soundFonts.defaultPreset {
        os_log(.info, log: log, "using soundFonts.defaultPreset")
        setActive(preset: defaultPreset, playSample: false)
      }
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
