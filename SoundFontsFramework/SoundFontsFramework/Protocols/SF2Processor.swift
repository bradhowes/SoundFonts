// Copyright © 2022 Brad Howes. All rights reserved.

import Foundation
import AVFAudio
import os.log

public protocol LoadableSampler: AnyObject {
  func loadAndActivate(url: URL, preset: Preset) -> NSError?
}

extension AVAudioUnitSampler: LoadableSampler {
  public func loadAndActivate(url: URL, preset: Preset) -> NSError? {
    do {
      try loadSoundBankInstrument(at: url,
                                  program: UInt8(preset.program),
                                  bankMSB: UInt8(preset.bankMSB),
                                  bankLSB: UInt8(preset.bankLSB))
    } catch let error as NSError {
      switch error.code {
      case -43, -54: // permission error for SF2 file
        NotificationCenter.default.post(name: .soundFontFileAccessDenied, object: url.lastPathComponent)
      default:
        os_log(.error, "AVAudioUnitSampler.loadSoundBankInstrument failed - %d %{public}s", errno,
               error.localizedDescription)
      }
      return error
    }
    return nil
  }
}
