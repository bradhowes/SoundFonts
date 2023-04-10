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

  public enum State: Equatable {
    case starting
    case pending(ActivePresetKind)
    case normal
  }

  private lazy var log = Logging.logger("ActivePresetManager")
  private let soundFonts: SoundFontsProvider
  private let favorites: FavoritesProvider
  private let selectedSoundFontManager: SelectedSoundFontManager
  private let settings: Settings
  private var notificationObserver: NotificationObserver?

  private let debounceDelay = 0.3
  private var activityDebounceTimer: Timer?

  public private(set) var state: State = .starting

  /// The currently active preset (if any)
  public private(set) var active: ActivePresetKind = .none {
    didSet {
      isLoading = true
    }
  }

  public private(set) var isLoading: Bool = false

  public var activeSoundFontKey: SoundFont.Key? { active.soundFontAndPreset?.soundFontKey }

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
    os_log(.debug, log: log, "init")

    soundFonts.subscribe(self, notifier: soundFontsChangedNotificationInBackground)
    favorites.subscribe(self, notifier: favoritesChangedNotificationInBackground)
    presetLoadingObserver = AudioEngine.presetLoadingChangeNotification.registerOnAny { [weak self] loading in
      if let self = self, !loading {
        self.isLoading = false
        self.notify(.loaded(preset: self.active))
      }
    }

    notificationObserver = MIDIEventRouter.monitorActionActivity { payload in
      switch payload.action {
      case .selectFavorite:
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

      default:
        break
      }
    }
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
    setActive(.favorite(favoriteKey: favorite.key, soundFontAndPreset: favorite.soundFontAndPreset),
              playSample: playSample)
  }

  /**
   Set a new active value.

   - parameter kind: wrapped value to set
   - parameter playSample: if true, play a note using the new preset
   */
  public func setActive(_ kind: ActivePresetKind, playSample: Bool = false) {
    os_log(.debug, log: log, "setActive BEGIN - %{public}s", kind.description)

    guard state == .normal else {
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

    notify(.changed(old: old, new: kind, playSample: playSample))
    os_log(.debug, log: log, "setActive END")
  }

  /**
   Restore an active value.

   - parameter kind: wrapped value to set
   */
  public func restoreActive(_ kind: ActivePresetKind) {
    os_log(.debug, log: log, "restoreActive BEGIN - %{public}s", kind.description)
    switch state {
    case .starting: state = .pending(kind)
    case .pending: state = .pending(kind)
    case .normal: setActive(kind)
    }
    os_log(.debug, log: log, "restoreActive END")
  }

  private func updateState() {
    os_log(.debug, log: log, "updateState BEGIN")

    guard soundFonts.isRestored && favorites.isRestored else {
      os_log(.debug, log: log, "updateState END - not restored")
      return
    }

    switch state {
    case .starting:
      os_log(.debug, log: log, "updateState - starting -> normal")
      state = .normal
      if let defaultPreset = soundFonts.defaultPreset {
        os_log(.debug, log: log, "updateState - using defaultPreset")
        setActive(.preset(soundFontAndPreset: defaultPreset))
      }

    case .pending(let pending):
      os_log(.debug, log: log, "updateState - pending -> normal")
      state = .normal
      setActive(rebuild(pending))

    case .normal:
      // This can happen when the config file is reloaded
      os_log(.debug, log: log, "updateState - normal -> normal")
    }

    precondition(state == .normal)
    os_log(.debug, log: log, "updateState END")
  }

  private func rebuild(_ kind: ActivePresetKind) -> ActivePresetKind {
    os_log(.debug, log: log, "rebuild BEGIN - %{public}s", kind.description)

    switch kind {
    case .preset:
      os_log(.debug, log: log, "rebuild END - using same")
      return kind

    case let .favorite(favoriteKey, soundFontAndPreset):
      os_log(.debug, log: log, "rebuild - favorite: %{public}s %{public}s", favoriteKey.uuidString,
             soundFontAndPreset.itemName)
      if let favorite = favorites.getBy(key: favoriteKey) {
        os_log(.debug, log: log, "rebuild END - using favorite")
        return .favorite(favoriteKey: favorite.key, soundFontAndPreset: favorite.soundFontAndPreset)
      } else if soundFonts.resolve(soundFontAndPreset: soundFontAndPreset) != nil {
        os_log(.debug, log: log, "rebuild END - using preset")
        return .preset(soundFontAndPreset: soundFontAndPreset)
      } else if let preset = soundFonts.defaultPreset {
        os_log(.debug, log: log, "rebuild END - using default preset")
        return .preset(soundFontAndPreset: preset)
      } else {
        os_log(.debug, log: log, "rebuild END - using none")
        return .none
      }
    case .none:
      if let defaultPreset = soundFonts.defaultPreset {
        os_log(.debug, log: log, "rebuild END - using default preset")
        return .preset(soundFontAndPreset: defaultPreset)
      }
      os_log(.debug, log: log, "rebuild END - using none")
      return .none
    }
  }
}

extension ActivePresetManager {

  private func favoritesChangedNotificationInBackground(_ event: FavoritesEvent) {
    if case .restored = event {
      DispatchQueue.main.async { self.updateState() }
    }
  }

  private func soundFontsChangedNotificationInBackground(_ event: SoundFontsEvent) {
    if case .restored = event {
      DispatchQueue.main.async { self.updateState() }
    }
  }

  private func save(_ kind: ActivePresetKind) {
    os_log(.debug, log: log, "save - %{public}s", kind.description)
    settings.lastActivePreset = kind
  }

  private func isValid(_ active: ActivePresetKind) -> Bool {
    precondition(soundFonts.isRestored)
    guard let soundFontAndPreset = active.soundFontAndPreset else { return false }
    return soundFonts.resolve(soundFontAndPreset: soundFontAndPreset) != nil
  }

  private func selectNextFavorite() {
    os_log(.debug, log: log, "selectNextFavorite")
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

  private func selectPreviousFavorite() {
    os_log(.debug, log: log, "selectPreviousFavorite")
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
