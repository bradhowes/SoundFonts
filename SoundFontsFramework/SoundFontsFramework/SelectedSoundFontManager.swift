// Copyright © 2018 Brad Howes. All rights reserved.

import Foundation
import os

public enum SelectedSoundFontEvent: CustomStringConvertible {
  case changed(old: SoundFont?, new: SoundFont?)

  public var description: String {
    switch self {
    case let .changed(old, new): return "<SelectedSoundFontEvent: changed \(old.descriptionOrNil) \(new.descriptionOrNil)>"
    }
  }
}

public final class SelectedSoundFontManager: SubscriptionManager<SelectedSoundFontEvent> {
  private lazy var log = Logging.logger("SelectedSoundFontManager")

  public private(set) var selected: SoundFont?

  public init() {
    super.init()
  }

  public func setSelected(_ soundFont: SoundFont) {
    os_log(.info, log: log, "setSelected BEGIN - %{public}s %{public}s", soundFont.displayName,
           String.pointer(soundFont))
    if selected != soundFont {
      let old = selected
      selected = soundFont
      notify(.changed(old: old, new: soundFont))
    }
    os_log(.info, log: log, "setSelected END")
  }

  public func clearSelected() {
    guard selected != nil else { return }
    let old = selected
    selected = nil
    notify(.changed(old: old, new: nil))
  }
}
