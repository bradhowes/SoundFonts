// Copyright © 2018 Brad Howes. All rights reserved.

import Foundation
import os

public enum SelectedSoundFontEvent {
    case changed(old: LegacySoundFont?, new: LegacySoundFont?)
}

public final class SelectedSoundFontManager: SubscriptionManager<SelectedSoundFontEvent> {
    private let log = Logging.logger("SelSF")

    private(set) var selected: LegacySoundFont?

    public init() {
        super.init()
        os_log(.info, log: log, "selected: %s %s", selected?.displayName ?? "nil", String.pointer(selected))
    }

    public func setSelected(_ soundFont: LegacySoundFont) {
        os_log(.info, log: log, "setSelected: %s %s", soundFont.displayName, String.pointer(soundFont))
        guard selected != soundFont else {
            os_log(.info, log: log, "already active")
            return
        }

        let old = selected
        selected = soundFont
        notify(.changed(old: old, new: soundFont))
    }

    public func clearSelected() {
        guard selected != nil else { return }
        let old = selected
        selected = nil
        notify(.changed(old: old, new: nil))
    }
}
