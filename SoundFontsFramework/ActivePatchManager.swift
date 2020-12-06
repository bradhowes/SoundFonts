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
        guard soundFonts.restored else { return }
        guard kind != active else { return }
        let prev = active
        active = kind
        save(kind)
        DispatchQueue.main.async { self.notify(.active(old: prev, new: kind, playSample: playSample)) }
    }

    public func clearActive() {
        setActive(.none, playSample: false)
    }

    public func restore(from data: Data) {
        let decoder = JSONDecoder()
        if let activePatchKind = try? decoder.decode(ActivePatchKind.self, from: data) {
            if let soundFont = self.soundFont {
                selectedSoundFontManager.setSelected(soundFont)
            }
            setActive(activePatchKind)
        }
    }
}

extension ActivePatchManager {

    private func soundFontsChange(_ event: SoundFontsEvent) {

        // We only care about restoration event
        guard case .restored = event else { return }

        // If active property is already set, then just announce to others what it is
        guard case .none = active else {
            DispatchQueue.main.async { self.notify(.active(old: .none, new: self.active, playSample: false)) }
            return
        }

        if let restored = Self.restore() {
            setActive(restored, playSample: false)
        }
        else if let defaultPreset = soundFonts.defaultPreset {
            setActive(preset: defaultPreset, playSample: false)
        }
    }

    static func restore() -> ActivePatchKind? { decode(Settings.instance.lastActivePatch) }

    public static func decode(_ data: Data) -> ActivePatchKind? { try? JSONDecoder().decode(ActivePatchKind.self, from: data) }
    public static func encode(_ kind: ActivePatchKind) -> Data? { try? JSONEncoder().encode(kind) }

    private func save(_ kind: ActivePatchKind) {
        // guard inApp else { return }
        os_log(.info, log: log, "save")
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
