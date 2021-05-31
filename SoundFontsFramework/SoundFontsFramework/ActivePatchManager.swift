// Copyright © 2020 Brad Howes. All rights reserved.

import Foundation
import os

/// The event notifications that can come from an ActivePatchManager subscription.
public enum ActivePatchEvent {

  /**
     Change event

     - Parameter old: the previous active patch
     - Parameter new: the new active patch
     - Parameter playSample: if true, play a note using the new patch
     */
  case active(old: ActivePatchKind, new: ActivePatchKind, playSample: Bool)
}

/// Maintains the active SoundFont patch being used for sound generation. There should only ever be one instance of this
/// class, but this is not enforced.
public final class ActivePatchManager: SubscriptionManager<ActivePatchEvent> {
  private lazy var log = Logging.logger("ActivePatchManager")
  private let soundFonts: SoundFonts
  private let selectedSoundFontManager: SelectedSoundFontManager

  private var pending: ActivePatchKind = .none

  /// The currently active patch (if any)
  public private(set) var active: ActivePatchKind

  /// The currently active sound font (if any)
  public var activeSoundFont: LegacySoundFont? {
    guard let key = active.soundFontAndPatch?.soundFontKey else { return nil }
    return soundFonts.getBy(key: key)
  }

  /// The currently active preset instance (if any)
  public var activePatch: LegacyPatch? {
    guard let index = active.soundFontAndPatch?.patchIndex else { return nil }
    return activeSoundFont?.patches[index]
  }

  /// The currently active preset instance (if any)
  public var activeFavorite: LegacyFavorite? { active.favorite }

  /// The preset configuration for the currently active preset or favorite
  public var activePresetConfig: PresetConfig? {
    activeFavorite?.presetConfig ?? activePatch?.presetConfig
  }

  /// Obtain the last-saved active patch value
  static var restoredActivePatchKind: ActivePatchKind? {
    ActivePatchKind.decodeFromData(Settings.instance.lastActivePatch)
  }

  /**
     Construct new manager

     - parameter soundFont: the sound font manager
     - parameter selectedSoundFontManager: the manager of the selected sound font
     - parameter inApp: true if the running inside the app, false if running in the AUv3 extension
     */
  public init(soundFonts: SoundFonts, selectedSoundFontManager: SelectedSoundFontManager) {
    self.active = .none
    self.soundFonts = soundFonts
    self.selectedSoundFontManager = selectedSoundFontManager
    super.init()
    os_log(.info, log: log, "init")
    soundFonts.subscribe(self, notifier: soundFontsChange)
    os_log(.info, log: log, "active: %{public}s", active.description)
  }

  /**
     Obtain the sound font instance that corresponds to the given preset key.

     - parameter soundFontAndPatch: the preset key to resolve
     - returns: optional sound font instance that corresponds to the given key
     */
  public func resolveToSoundFont(_ soundFontAndPatch: SoundFontAndPatch) -> LegacySoundFont? {
    return soundFonts.getBy(key: soundFontAndPatch.soundFontKey)
  }

  /**
     Obtain the preset instance that corresponds to the given preset key.

     - parameter soundFontAndPatch: the preset key to resolve
     - returns: optional patch instance that corresponds to the given key
     */
  public func resolveToPatch(_ soundFontAndPatch: SoundFontAndPatch) -> LegacyPatch? {
    return soundFonts.getBy(key: soundFontAndPatch.soundFontKey)?.patches[
      soundFontAndPatch.patchIndex]
  }

  /**
     Set a new active preset.

     - parameter preset: the preset to make active
     - parameter playSample: if true, play a note using the new preset
     */
  @discardableResult
  public func setActive(preset: SoundFontAndPatch, playSample: Bool) -> Bool {
    setActive(.preset(soundFontAndPatch: preset), playSample: playSample)
  }

  /**
     Make a favorite the active preset.

     - parameter favorite: the favorite to make active
     - parameter playSample: if true, play a note using the new preset
     */
  @discardableResult
  public func setActive(favorite: LegacyFavorite, playSample: Bool) -> Bool {
    setActive(.favorite(favorite: favorite), playSample: playSample)
  }

  /**
     Set a new active value.

     - parameter kind: wrapped value to set
     - parameter playSample: if true, play a note using the new preset
     */
  @discardableResult
  public func setActive(_ kind: ActivePatchKind, playSample: Bool = false) -> Bool {
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

extension ActivePatchManager {

  private func soundFontsChange(_ event: SoundFontsEvent) {

    // We only care about restoration event
    guard case .restored = event else { return }
    os_log(.info, log: log, "SF collection restored")

    if pending != .none {
      os_log(.info, log: log, "using pending value")
      setActive(pending, playSample: false)
    } else if let restored = Self.restoredActivePatchKind,
      isValid(restored)
    {
      os_log(.info, log: log, "using restored value from UserDefaults")
      setActive(restored, playSample: false)
    } else if let defaultPreset = soundFonts.defaultPreset {
      os_log(.info, log: log, "using soundFonts.defaultPreset")
      setActive(preset: defaultPreset, playSample: false)
    }
  }

  private func save(_ kind: ActivePatchKind) {
    os_log(.info, log: log, "save - %{public}s", kind.description)
    DispatchQueue.global(qos: .background).async {
      if let data = kind.encodeToData() {
        Settings.instance.lastActivePatch = data
      }
    }
  }

  private func isValid(_ active: ActivePatchKind) -> Bool {
    guard soundFonts.restored else { return true }
    guard let soundFontAndPatch = active.soundFontAndPatch else { return false }
    return soundFonts.resolve(soundFontAndPatch: soundFontAndPatch) != nil
  }
}
