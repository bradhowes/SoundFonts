// Copyright © 2018 Brad Howes. All rights reserved.

import Foundation
import os

public enum SelectedSoundFontEvent: CustomStringConvertible {
  case changed(old: SoundFont.Key?, new: SoundFont.Key?)

  public var description: String {
    switch self {
    case let .changed(old, new): return "<SelectedSoundFontEvent: changed \(old.descriptionOrNil) \(new.descriptionOrNil)>"
    }
  }
}

/**
 Maintains the currently *selected* sound font, the one whose presets are being shown. This is in contrast to
 the *active* sound font which is the sound font that contains the preset that is currently active and in use by the
 synth. They can be the same, but not always such as when a user is browsing sound fonts and looking at their presets.
 Selecting a preset will make the selected sound font and the active sound font the same.
 */
public final class SelectedSoundFontManager: SubscriptionManager<SelectedSoundFontEvent> {
  private lazy var log: Logger = Logging.logger("SelectedSoundFontManager")

  public private(set) var selected: SoundFont.Key?

  public func setSelected(_ soundFont: SoundFont) {
    log.debug("setSelected BEGIN - \(soundFont.displayName, privacy: .public) \(String.pointer(soundFont), privacy: .public)")
    if selected != soundFont.key {
      let old = selected
      selected = soundFont.key
      notify(.changed(old: old, new: soundFont.key))
    }
    log.debug("setSelected END")
  }

  public func clearSelected() {
    guard selected != nil else { return }
    let old = selected
    selected = nil
    notify(.changed(old: old, new: nil))
  }
}
