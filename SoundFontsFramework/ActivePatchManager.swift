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

    public private(set) var active: ActivePatchKind {
        didSet { os_log(.info, log: log, "set active: %s", active.description) }
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

    public init(soundFonts: SoundFonts) {
        self.soundFonts = soundFonts
        self.active = Self.restore() ?? (soundFonts.isEmpty ? .none : .normal(soundFontAndPatch: soundFonts.getBy(index: 0).makeSoundFontAndPatch(for: 0)))
        super.init()
        os_log(.info, log: log, "active: %s", active.description)
    }

    public func resolveToSoundFont(_ soundFontAndPatch: SoundFontAndPatch) -> LegacySoundFont? {
        return soundFonts.getBy(key: soundFontAndPatch.soundFontKey)
    }

    public func resolveToPatch(_ soundFontAndPatch: SoundFontAndPatch) -> LegacyPatch? {
        return soundFonts.getBy(key: soundFontAndPatch.soundFontKey)?.patches[soundFontAndPatch.patchIndex]
    }

    public func setActive(preset: SoundFontAndPatch, playSample: Bool) { setActive(.normal(soundFontAndPatch: preset), playSample: playSample) }

    public func setActive(favorite: LegacyFavorite, playSample: Bool) { setActive(.favorite(favorite: favorite), playSample: playSample) }

    public func clearActive() { setActive(.none, playSample: false) }

    public func restore(from data: Data) {
        let decoder = JSONDecoder()
        if let activePatchKind = try? decoder.decode(ActivePatchKind.self, from: data) {
            setActive(activePatchKind)
        }
    }
}

extension ActivePatchManager {

    private func setActive(_ patch: ActivePatchKind, playSample: Bool = false) {
        os_log(.info, log: log, "setActive: %s", patch.description)
        let prev = active
        active = patch
        DispatchQueue.main.async { self.notify(.active(old: prev, new: patch, playSample: playSample)) }
        save()
    }

    static func restore() -> ActivePatchKind? {
        let decoder = JSONDecoder()
        let data = settings.lastActivePatch
        return try? decoder.decode(ActivePatchKind.self, from: data)
    }

    private func save() {
        os_log(.info, log: log, "save")
        let copy = self.active
        DispatchQueue.global(qos: .background).async {
            let encoder = JSONEncoder()
            if let data = try? encoder.encode(copy) {
                settings.lastActivePatch = data
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
