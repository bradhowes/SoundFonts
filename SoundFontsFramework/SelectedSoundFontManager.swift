// Copyright © 2018 Brad Howes. All rights reserved.

import Foundation
import os

public enum SelectedSoundFontEvent {
    case changed(old: SoundFont?, new: SoundFont?)
}

public final class SelectedSoundFontManager: SubscriptionManager<SelectedSoundFontEvent> {
    private let log = Logging.logger("SelSF")

    private(set) var selected: SoundFont?

    public init(activePatchManager: ActivePatchManager) {
        self.selected = activePatchManager.soundFont
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
        notify(.changed(old: old, new: soundFont))
    }
}
