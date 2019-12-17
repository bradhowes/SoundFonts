// Copyright © 2018 Brad Howes. All rights reserved.

import Foundation
import os

extension SettingKeys {
    static let lastActivePatch = SettingKey<Data>("lastActivePatch", defaultValue: Data())
}

enum ActivePatchKind: CustomStringConvertible, Codable, Equatable {

    case normal(soundFontPatch: SoundFontPatch)

    case favorite(favorite: Favorite)

    var soundFontPatch: SoundFontPatch {
        switch self {
        case .normal(let soundFontPatch): return soundFontPatch
        case .favorite(let favorite): return favorite.soundFontPatch
        }
    }

    var favorite: Favorite? {
        switch self {
        case .normal: return nil
        case .favorite(let favorite): return favorite
        }
    }

    var description: String {
        switch self {
        case let .normal(soundFontPatch: soundFontPatch): return ".normal(\(soundFontPatch)"
        case let .favorite(favorite: favorite): return ".favorite(\(favorite))"
        }
    }

    private enum InternalKey: Int {
        case normal = 0
        case favorite = 1

        static func key(for kind: ActivePatchKind) -> InternalKey {
            switch kind {
            case .normal(soundFontPatch: _): return .normal
            case .favorite(favorite:_): return .favorite
            }
        }
    }

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        guard let kind = InternalKey(rawValue: try container.decode(Int.self)) else { fatalError() }
        switch kind {
        case .normal: self = .normal(soundFontPatch: try container.decode(SoundFontPatch.self))
        case .favorite: self = .favorite(favorite: try container.decode(Favorite.self))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(InternalKey.key(for: self).rawValue)
        switch self {
        case .normal(let soundFontPatch): try container.encode(soundFontPatch)
        case .favorite(let favorite): try container.encode(favorite)
        }
    }
}

enum ActivePatchEvent {
    case active(old: ActivePatchKind, new: ActivePatchKind)
}

/**
 Maintains the active SoundFont patch being used for sound generation.
 */
final class ActivePatchManager: SubscriptionManager<ActivePatchEvent> {
    private let log = Logging.logger("ActPatMan")

    private(set) var active: ActivePatchKind

    var favorite: Favorite? { active.favorite }
    var soundFontPatch: SoundFontPatch { active.soundFontPatch }
    var soundFont: SoundFont { soundFontPatch.soundFont }
    var patch: Patch { soundFont.patches[soundFontPatch.patchIndex] }

    init(soundFonts: SoundFonts) {
        self.active = Self.restore() ??
            .normal(soundFontPatch: soundFonts.getBy(index: 0).makeSoundFontPatch(for: 0))
        os_log(.info, log: log, "active: %s", active.description)
    }

    func setActive(_ patch: ActivePatchKind) {
        os_log(.info, log: log, "setActive: %s", patch.description)
        guard active != patch else {
            os_log(.info, log: log, "already active")
            return
        }

        let prev = active
        active = patch
        save()
        notify(.active(old: prev, new: patch))
    }

    static func restore() -> ActivePatchKind? {
        let decoder = JSONDecoder()
        let data = Settings[.lastActivePatch]
        return try? decoder.decode(ActivePatchKind.self, from: data)
    }

    func save() {
        os_log(.info, log: log, "save")
        DispatchQueue.global(qos: .background).async {
            let encoder = JSONEncoder()
            if let data = try? encoder.encode(self.active) {
                Settings[.lastActivePatch] = data
            }
        }
    }
}
