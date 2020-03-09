// Copyright © 2018 Brad Howes. All rights reserved.

import Foundation
import os

extension SettingKeys {
    static let lastSelectedSoundFont = SettingKey<Data>("lastSelectedSoundFont", defaultValue: Data())
}

public enum SelectedSoundFontEvent {
    case changed(old: SoundFont?, new: SoundFont?)
}

public final class SelectedSoundFontManager: SubscriptionManager<SelectedSoundFontEvent> {
    private let log = Logging.logger("SelSF")

    private(set) var selected: SoundFont?

    public init(activePatchManager: ActivePatchManager) {
        self.selected = Self.restore() ?? activePatchManager.active.soundFontPatch?.soundFont ?? nil
        os_log(.info, log: log, "selected: %s", selected?.description ?? "nil")
    }

    public func setSelected(_ soundFont: SoundFont?) {
        os_log(.info, log: log, "setSelected: %s", soundFont?.description ?? "nil")
        guard selected != soundFont else {
            os_log(.info, log: log, "already active")
            return
        }

        let old = selected
        selected = soundFont
        self.save()
        notify(.changed(old: old, new: soundFont))
    }

    public static func restore() -> SoundFont? {
        let decoder = JSONDecoder()
        let data = Settings[.lastSelectedSoundFont]
        return try? decoder.decode(SoundFont.self, from: data)
    }

    public func save() {
        DispatchQueue.global(qos: .background).async {
            let encoder = JSONEncoder()
            if let data = try? encoder.encode(self.selected) {
                Settings[.lastSelectedSoundFont] = data
            }
        }
    }
}
