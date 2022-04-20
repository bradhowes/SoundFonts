// Copyright © 2022 Brad Howes. All rights reserved.

import Foundation
import AVFAudio
import os.log

/**
 Abstraction for an entity that can load a preset from a URL.
 */
public protocol LoadablePreset: AnyObject {

  /**
   Load and activate a preset found in an SF2 file.

   - parameter url: the location of the file to load from
   - parameter preset: the preset to make active
   - returns: optional error indicating any issue encountered
   */
  func loadAndActivatePreset(_ preset: Preset, from url: URL) -> NSError?
}

extension AVAudioUnitSampler: LoadablePreset {

  public func loadAndActivatePreset(_ preset: Preset, from url: URL) -> NSError? {
    do {
      try loadSoundBankInstrument(at: url,
                                  program: UInt8(preset.program),
                                  bankMSB: UInt8(preset.bankMSB),
                                  bankLSB: UInt8(preset.bankLSB))
    } catch let error as NSError {
      switch error.code {
      case -43: // not found
        NotificationCenter.default.post(name: .soundFontFileNotAvailable, object: url.lastPathComponent)
      case -54: // permission error for SF2 file
        NotificationCenter.default.post(name: .soundFontFileAccessDenied, object: url.lastPathComponent)
      default:
        break
      }
      os_log(.error, "AVAudioUnitSampler.loadSoundBankInstrument failed - errno: %d error: %{public}s", errno,
             error.localizedDescription)
      return error
    }
    return nil
  }
}
