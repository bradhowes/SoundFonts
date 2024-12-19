// Copyright © 2020 Brad Howes. All rights reserved.

import Foundation
import os

/// The event notifications that can come from an ActivePresetManager subscription.
public enum ActivePresetEvent: CustomStringConvertible {

  /**
   Changed event

   - Parameter old: the previous active preset
   - Parameter new: the new active preset
   - Parameter playSample: if true, play a note using the new preset
   */
  case changed(old: ActivePresetKind, new: ActivePresetKind, playSample: Bool)

  case loaded(preset: ActivePresetKind)

  public var description: String {
    switch self {
    case let .changed(old, new, _): return "<ActivePresetEvent: changed old: \(old) new: \(new)>"
    case let .loaded(preset): return "<ActivePresetEvent: loaded: \(preset)>"
    }
  }
}

/**
 Maintains the active SoundFont preset being used for sound generation. When it changes, it sends an ActivePresetEvent
 event to its subscribers.s
 */
public final class ActivePresetManager: SubscriptionManager<ActivePresetEvent> {

  enum State: Equatable {
    case starting
    case pending(ActivePresetKind)
    case normal
  }

  private lazy var log: Logger = Logging.logger("ActivePresetManager")
  private let soundFonts: SoundFontsProvider
  private let favorites: FavoritesProvider
  private let selectedSoundFontManager: SelectedSoundFontManager
  private let settings: Settings
  private var notificationObserver: NotificationObserver?

  private let debounceDelay = 0.3
  private var activityDebounceTimer: Timer?

  private(set) var state: State = .starting

  /// The currently active preset (if any)
  private(set) var active: ActivePresetKind = .none

  var activeSoundFontKey: SoundFont.Key? { active.soundFontAndPreset?.soundFontKey }

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
  public var activeFavorite: Favorite? {
    guard let key = active.favoriteKey else { return nil }
    return favorites.getBy(key: key)
  }

  /// The preset configuration for the currently active preset or favorite
  public var activePresetConfig: PresetConfig? {
    activeFavorite?.presetConfig ?? activePreset?.presetConfig
  }

  private var presetLoadingObserver: NotificationObserver?

  /**
   Construct new manager

   - parameter soundFonts: the collection of sound fonts
   - parameter favorites: the collection of favorites
   - parameter selectedSoundFontManager: the manager of the selected sound font
   - parameter settings: the app settings
   */
  public init(soundFonts: SoundFontsProvider, favorites: FavoritesProvider,
              selectedSoundFontManager: SelectedSoundFontManager, settings: Settings) {
    self.soundFonts = soundFonts
    self.favorites = favorites
    self.selectedSoundFontManager = selectedSoundFontManager
    self.settings = settings

    super.init()
    log.debug("init")

    soundFonts.subscribe(self, notifier: soundFontsChangedNotificationInBackground)
    favorites.subscribe(self, notifier: favoritesChangedNotificationInBackground)
    notificationObserver = MIDIEventRouter.monitorActionActivity { self.handleAction(payload: $0) }
  }
}

public extension ActivePresetManager {

  /**
   Obtain the sound font instance that corresponds to the given preset key.

   - parameter soundFontAndPreset: the preset key to resolve
   - returns: optional sound font instance that corresponds to the given key
   */
  func resolveToSoundFont(_ soundFontAndPreset: SoundFontAndPreset) -> SoundFont? {
    soundFonts.getBy(key: soundFontAndPreset.soundFontKey)
  }

  /**
   Obtain the preset instance that corresponds to the given preset key.

   - parameter soundFontAndPreset: the preset key to resolve
   - returns: optional patch instance that corresponds to the given key
   */
  func resolveToPreset(_ soundFontAndPreset: SoundFontAndPreset) -> Preset? {
    soundFonts.getBy(key: soundFontAndPreset.soundFontKey)?.presets[soundFontAndPreset.presetIndex]
  }

  /**
   Set a new active preset.

   - parameter preset: the preset to make active
   - parameter playSample: if true, play a note using the new preset
   */
  func setActive(preset: SoundFontAndPreset, playSample: Bool) {
    setActive(.preset(soundFontAndPreset: preset), playSample: playSample)
  }

  /**
   Make a favorite the active preset.

   - parameter favorite: the favorite to make active
   - parameter playSample: if true, play a note using the new preset
   */
  func setActive(favorite: Favorite, playSample: Bool) {
    setActive(.favorite(favoriteKey: favorite.key, soundFontAndPreset: favorite.soundFontAndPreset),
              playSample: playSample)
  }

  /**
   Set a new active value.

   - parameter kind: wrapped value to set
   - parameter playSample: if true, play a note using the new preset
   */
  func setActive(_ kind: ActivePresetKind, playSample: Bool = false) {
    log.debug("setActive BEGIN - \(kind.description, privacy: .public)")

    guard state == .normal else {
      log.debug("setActive END - not restored")
      return
    }

    guard active != kind else {
      log.debug("setActive END - preset already active")
      return
    }

    let old = active
    active = kind
    save(kind)

    notify(.changed(old: old, new: kind, playSample: playSample))
    log.debug("setActive END")
  }

  /**
   Restore an active value.

   - parameter kind: wrapped value to set
   */
  func restoreActive(_ kind: ActivePresetKind) {
    log.debug("restoreActive BEGIN - \(kind.description, privacy: .public)")
    switch state {
    case .starting: state = .pending(kind)
    case .pending: state = .pending(kind)
    case .normal: setActive(kind)
    }
    log.debug("restoreActive END")
  }
}

private extension ActivePresetManager {

  func updateState() {
    log.debug("updateState BEGIN")

    guard soundFonts.isRestored && favorites.isRestored else {
      log.debug("updateState END - not restored")
      return
    }

    switch state {
    case .starting:
      log.debug("updateState - starting -> normal")
      state = .normal
      if let defaultPreset = soundFonts.defaultPreset {
        log.debug("updateState - using defaultPreset")
        setActive(.preset(soundFontAndPreset: defaultPreset))
      }

    case .pending(let pending):
      log.debug("updateState - pending -> normal")
      state = .normal
      setActive(rebuild(pending))

    case .normal:
      // This can happen when the config file is reloaded
      log.debug("updateState - normal -> normal")
    }

    precondition(state == .normal)
    log.debug("updateState END")
  }

  func rebuild(_ kind: ActivePresetKind) -> ActivePresetKind {
    log.debug("rebuild BEGIN - \(kind.description, privacy: .public)")

    switch kind {
    case .preset:
      log.debug("rebuild END - using same")
      return kind

    case let .favorite(favoriteKey, soundFontAndPreset):
      log.debug("rebuild - favorite: \(favoriteKey.uuidString, privacy: .public) \(soundFontAndPreset.itemName, privacy: .public)")
      if let favorite = favorites.getBy(key: favoriteKey) {
        log.debug("rebuild END - using favorite")
        return .favorite(favoriteKey: favorite.key, soundFontAndPreset: favorite.soundFontAndPreset)
      } else if soundFonts.resolve(soundFontAndPreset: soundFontAndPreset) != nil {
        log.debug("rebuild END - using preset")
        return .preset(soundFontAndPreset: soundFontAndPreset)
      } else if let preset = soundFonts.defaultPreset {
        log.debug("rebuild END - using default preset")
        return .preset(soundFontAndPreset: preset)
      } else {
        log.debug("rebuild END - using none")
        return .none
      }
    case .none:
      if let defaultPreset = soundFonts.defaultPreset {
        log.debug("rebuild END - using default preset")
        return .preset(soundFontAndPreset: defaultPreset)
      }
      log.debug("rebuild END - using none")
      return .none
    }
  }

  func handleAction(payload: MIDIEventRouter.ActionActivityPayload) {
    guard case .selectFavorite = payload.action  else { return }
    switch payload.kind {
    case .relative:
      if payload.value > 64 {
        self.selectNextFavorite()
      } else if payload.value < 64 {
        self.selectPreviousFavorite()
      }
    case .absolute:
      let scale = Double(payload.value) / Double(127)
      let index = Int((Double(favorites.count - 1) * scale).rounded())
      favorites.selected(index: index)
    case .onOff:
      break
    }
  }

  func favoritesChangedNotificationInBackground(_ event: FavoritesEvent) {
    if case .restored = event {
      DispatchQueue.main.async { self.updateState() }
    }
  }

  func soundFontsChangedNotificationInBackground(_ event: SoundFontsEvent) {
    if case .restored = event {
      DispatchQueue.main.async { self.updateState() }
    }
  }

  func save(_ kind: ActivePresetKind) {
    log.debug("save - \(kind.description, privacy: .public)")
    settings.lastActivePreset = kind
  }

  func isValid(_ active: ActivePresetKind) -> Bool {
    precondition(soundFonts.isRestored)
    guard let soundFontAndPreset = active.soundFontAndPreset else { return false }
    return soundFonts.resolve(soundFontAndPreset: soundFontAndPreset) != nil
  }

  func selectNextFavorite() {
    log.debug("selectNextFavorite")
    guard
      let key = active.favoriteKey,
      let index = favorites.index(of: key),
      index < favorites.count - 1
    else {
      return
    }

    if activityDebounceTimer != nil { return }

    favorites.selected(index: index + 1)
    self.activityDebounceTimer = Timer.once(after: debounceDelay) { _ in
      self.activityDebounceTimer = nil
    }
  }

  func selectPreviousFavorite() {
    log.debug("selectPreviousFavorite")
    guard
      let key = active.favoriteKey,
      let index = favorites.index(of: key),
      index > 0
    else {
      return
    }

    if activityDebounceTimer != nil { return }

    favorites.selected(index: index - 1)
    self.activityDebounceTimer = Timer.once(after: debounceDelay) { _ in
      self.activityDebounceTimer = nil
    }
  }
}
