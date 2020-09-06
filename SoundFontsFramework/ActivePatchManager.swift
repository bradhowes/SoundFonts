// Copyright © 2018 Brad Howes. All rights reserved.

import Foundation
import os

extension SettingKeys {
    static let lastActivePatch = SettingKey<Data>("lastActivePatch", defaultValue: Data())
}

public enum ActivePatchKind: CustomStringConvertible, Codable, Equatable {

    case normal(soundFontAndPatch: SoundFontAndPatch)
    case favorite(favorite: Favorite)
    case none

    public var soundFontAndPatch: SoundFontAndPatch? {
        switch self {
        case .normal(let soundFontAndPatch): return soundFontAndPatch
        case .favorite(let favorite): return favorite.soundFontAndPatch
        case .none: return nil
        }
    }

    public var favorite: Favorite? {
        switch self {
        case .normal: return nil
        case .favorite(let favorite): return favorite
        case .none: return nil
        }
    }

    public var description: String {
        switch self {
        case let .normal(soundFontAndPatch: soundFontPatch): return ".normal(\(soundFontPatch)"
        case let .favorite(favorite: favorite): return ".favorite(\(favorite))"
        case .none: return "nil"
        }
    }

    private enum InternalKey: Int {
        case normal = 0
        case favorite = 1
        case none = 2

        static func key(for kind: ActivePatchKind) -> InternalKey {
            switch kind {
            case .normal(soundFontAndPatch: _): return .normal
            case .favorite(favorite:_): return .favorite
            case .none: return .none
            }
        }
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        guard let kind = InternalKey(rawValue: try container.decode(Int.self)) else { fatalError() }
        switch kind {
        case .normal: self = .normal(soundFontAndPatch: try container.decode(SoundFontAndPatch.self))
        case .favorite: self = .favorite(favorite: try container.decode(Favorite.self))
        case .none: self = .none
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(InternalKey.key(for: self).rawValue)
        switch self {
        case .normal(let soundFontPatch): try container.encode(soundFontPatch)
        case .favorite(let favorite): try container.encode(favorite)
        case .none: break
        }
    }
}

public enum ActivePatchEvent {
    case active(old: ActivePatchKind, new: ActivePatchKind, playSample: Bool)
}

/**
 Maintains the active SoundFont patch being used for sound generation.
 */
public final class ActivePatchManager: SubscriptionManager<ActivePatchEvent> {
    private let log = Logging.logger("ActPatMan")

    private let soundFonts: SoundFonts

    public private(set) var active: ActivePatchKind

    public var favorite: Favorite? { active.favorite }
    public var soundFontAndPatch: SoundFontAndPatch? { active.soundFontAndPatch }

    public var soundFont: SoundFont? {
        guard let key = soundFontAndPatch?.soundFontKey else { return nil }
        return soundFonts.getBy(key: key)
    }

    public var patch: Patch? {
        guard let index = soundFontAndPatch?.patchIndex else { return nil }
        return soundFont?.patches[index]
    }

    public init(soundFonts: SoundFonts) {
        self.soundFonts = soundFonts
        self.active = Self.restore() ??
            (soundFonts.count > 0
                ? .normal(soundFontAndPatch: soundFonts.getBy(index: 0).makeSoundFontAndPatch(for: 0))
                : .none)
        super.init()
        os_log(.info, log: log, "active: %s", active.description)
    }

    public func resolveToSoundFont(_ soundFontAndPatch: SoundFontAndPatch) -> SoundFont? {
        return soundFonts.getBy(key: soundFontAndPatch.soundFontKey)
    }

    public func resolveToPatch(_ soundFontAndPatch: SoundFontAndPatch) -> Patch? {
        return soundFonts.getBy(key: soundFontAndPatch.soundFontKey)?.patches[soundFontAndPatch.patchIndex]
    }

    public func setActive(_ patch: ActivePatchKind, playSample: Bool = false) {
        os_log(.info, log: log, "setActive: %s", patch.description)
        let prev = active
        active = patch
        DispatchQueue.main.async { self.notify(.active(old: prev, new: patch, playSample: playSample)) }
        save()
    }

    public static func restore() -> ActivePatchKind? {
        let decoder = JSONDecoder()
        let data = Settings[.lastActivePatch]
        return try? decoder.decode(ActivePatchKind.self, from: data)
    }

    public func save() {
        os_log(.info, log: log, "save")
        DispatchQueue.global(qos: .background).async {
            let encoder = JSONEncoder()
            if let data = try? encoder.encode(self.active) {
                Settings[.lastActivePatch] = data
            }
        }
    }
}

extension ActivePatchManager {

    public func validate(soundFonts: SoundFontsManager, favorites: FavoritesManager) {
        switch active {
        case .favorite(let favorite): if !favorites.validate(favorite) { active = .none }
        case .normal(let soundFontAndPatch): if !soundFonts.validate(soundFontAndPatch) { active = .none }
        case .none: break
        }
    }
}
