// Copyright © 2020 Brad Howes. All rights reserved.

import Foundation
import os

/**
 The event notifications that can come from an ActivePatchManager subscription.
 */
public enum ActivePatchEvent {

    /**
     Change event

     - Parameter old: the previous active patch
     - Parameter new: the new active patch
     - Parameter playSample: if true, play a note using the new patch
     */
    case active(old: ActivePatchKind, new: ActivePatchKind, playSample: Bool)
}

/**
 Maintains the active SoundFont patch being used for sound generation.
 */
public final class ActivePatchManager: SubscriptionManager<ActivePatchEvent> {
    private let log = Logging.logger("ActPatMan")
    private let soundFonts: SoundFonts
    private let selectedSoundFontManager: SelectedSoundFontManager
    private let inApp: Bool

    private var pending: ActivePatchKind = .none

    public private(set) var active: ActivePatchKind = .none {
        didSet { os_log(.info, log: log, "set active: %{public}s", active.description) }
    }

    public var favorite: LegacyFavorite? { active.favorite }
    public var soundFontAndPatch: SoundFontAndPatch? { active.soundFontAndPatch }

    public var soundFont: LegacySoundFont? {
        guard let key = soundFontAndPatch?.soundFontKey else { return nil }
        return soundFonts.getBy(key: key)
    }

    public var patch: LegacyPatch? {
        guard let index = soundFontAndPatch?.patchIndex else { return nil }
        return soundFont?.patches[index]
    }

    public init(soundFonts: SoundFonts, selectedSoundFontManager: SelectedSoundFontManager, inApp: Bool) {
        os_log(.info, log: log, "init")
        self.soundFonts = soundFonts
        self.selectedSoundFontManager = selectedSoundFontManager
        self.inApp = inApp
        super.init()
        soundFonts.subscribe(self, notifier: soundFontsChange)
        os_log(.info, log: log, "active: %{public}s", active.description)
    }

    public func resolveToSoundFont(_ soundFontAndPatch: SoundFontAndPatch) -> LegacySoundFont? {
        return soundFonts.getBy(key: soundFontAndPatch.soundFontKey)
    }

    public func resolveToPatch(_ soundFontAndPatch: SoundFontAndPatch) -> LegacyPatch? {
        return soundFonts.getBy(key: soundFontAndPatch.soundFontKey)?.patches[soundFontAndPatch.patchIndex]
    }

    public func setActive(preset: SoundFontAndPatch, playSample: Bool) {
        setActive(.normal(soundFontAndPatch: preset), playSample: playSample)
    }

    public func setActive(favorite: LegacyFavorite, playSample: Bool) {
        setActive(.favorite(favorite: favorite), playSample: playSample)
    }

    public func setActive(_ kind: ActivePatchKind, playSample: Bool = false) {
        os_log(.info, log: log, "setActive: %{public}s", kind.description)
        guard soundFonts.restored else {
            os_log(.info, log: log, "not yet restored - setting pending - current: %{public}s", kind.description)
            if pending == .none {
                pending = kind
            }
            return
        }

        pending = .none

        // guard kind != active else { return }
        let prev = active
        active = kind
        save(kind)
        DispatchQueue.main.async { self.notify(.active(old: prev, new: kind, playSample: playSample)) }
    }

    public func clearActive() {
        os_log(.info, log: log, "clearActive")
        setActive(.none, playSample: false)
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
        }
        else if let restored = Self.restore() {
            os_log(.info, log: log, "using restored value from UserDefaults")
            setActive(restored, playSample: false)
        }
        else if let defaultPreset = soundFonts.defaultPreset {
            os_log(.info, log: log, "using soundFonts.defaultPreset")
            setActive(preset: defaultPreset, playSample: false)
        }
    }

    static func restore() -> ActivePatchKind? { decode(Settings.instance.lastActivePatch) }

    public static func decode(_ data: Data) -> ActivePatchKind? { try? JSONDecoder().decode(ActivePatchKind.self, from: data) }
    public static func encode(_ kind: ActivePatchKind) -> Data? { try? JSONEncoder().encode(kind) }

    private func save(_ kind: ActivePatchKind) {
        os_log(.info, log: log, "save - %{public}s", kind.description)
        DispatchQueue.global(qos: .background).async {
            if let data = Self.encode(kind) {
                Settings.instance.lastActivePatch = data
            }
        }
    }
}

extension ActivePatchManager {

    public func validate(soundFonts: LegacySoundFontsManager, favorites: LegacyFavoritesManager) {
        switch active {
        case .favorite(let favorite): if !favorites.validate(favorite) { active = .none }
        case .normal(let soundFontAndPatch): if !soundFonts.validate(soundFontAndPatch) { active = .none }
        case .none: break
        }
    }
}
