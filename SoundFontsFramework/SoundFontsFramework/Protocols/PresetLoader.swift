// Copyright © 2022 Brad Howes. All rights reserved.

import Foundation
import AVFAudio
import os.log
import SoundFontInfoLib

/**
 Abstraction for an entity that can load a preset from a URL.
 */
public protocol PresetLoader: AnyObject {

  /**
   Load and activate a preset found in an SF2 file.

   - parameter url: the location of the file to load from
   - parameter preset: the preset to make active
   - returns: optional error indicating any issue encountered
   */
  func loadAndActivatePreset(_ preset: Preset, from url: URL) -> NSError?
}

extension AVAudioUnitSampler: PresetLoader {

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

extension SF2Engine: PresetLoader {
  public func loadAndActivatePreset(_ preset: Preset, from url: URL) -> NSError? {
    var err = self.load(url)
    switch err {
    case .fileNotFound:
      NotificationCenter.default.post(name: .soundFontFileNotAvailable, object: url.lastPathComponent)
      return NSError(domain: "SF2Engine", code: Int(err.rawValue))
    case .cannotAccessFile:
      NotificationCenter.default.post(name: .soundFontFileAccessDenied, object: url.lastPathComponent)
      return NSError(domain: "SF2Engine", code: Int(err.rawValue))
    default: break
    }

    err = self.selectPreset(Int32(preset.soundFontIndex))
    switch err {
    case .OK: break
    default: return NSError(domain: "SF2Engine", code: Int(err.rawValue))
    }

    return nil
  }
}
