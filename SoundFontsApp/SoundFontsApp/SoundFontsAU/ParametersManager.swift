// Copyright © 2021 Brad Howes. All rights reserved.

import os.log
import CoreAudioKit
import SoundFontsFramework

/**
 Manages the values in the AUParameterTree, making them reflect the current active preset setting when it changes as
 well as monitoring for value changes from a MIDI controller or host and making the current active preset reflect them.
 */
final class ParametersManager: NSObject {
  private let log = Logging.logger("ParameterOperator")

  private let soundFonts: SoundFonts
  private let selectedSoundFontManager: SelectedSoundFontManager
  private let activePresetManager: ActivePresetManager

  private var subscription: SubscriberToken?
  private lazy var audioUnitParameters = AudioUnitParameters(parameterHandler: self)

  private var soundFont = 0
  private var bank = 0
  private var program = 0
  private var updating = false

  public var parameterTree: AUParameterTree { audioUnitParameters.parameterTree }

  /**
   Construct new instance

   - parameter soundFonts: the container of known sound fonts
   - parameter selectedSoundFontManager: the manager of the active
   - parameter activePresetManager: <#Describe activePresetManager#>
   */
  public init(soundFonts: SoundFonts, selectedSoundFontManager: SelectedSoundFontManager,
       activePresetManager: ActivePresetManager) {
    os_log(.info, log: log, "init - BEGIN")

    self.soundFonts = soundFonts
    self.selectedSoundFontManager = selectedSoundFontManager
    self.activePresetManager = activePresetManager

    super.init()

    subscription = activePresetManager.subscribe(self) { event in
      switch event {
      case .active(_, _, _): self.reflectActivePreset()
      }
    }

    reflectActivePreset()
    os_log(.info, log: log, "init - END")
  }
}

extension ParametersManager: AUParameterHandler {

  /**
   Something changed a parameter value. If not us, use a preset that matches the new values.

   - parameter parameter: the parameter that changed
   - parameter value: the new value
   */
  func set(_ parameter: AUParameter, value: AUValue) {
    os_log(.info, log: log, "set - BEGIN: %d %f", parameter.address, value)
    guard let address = AudioUnitParameters.Address(rawValue: parameter.address) else { return }
    switch address {
    case .soundFont: soundFont = Int(value).clamped(to: 0...127)
    case .bank: bank = Int(value).clamped(to: 0...127)
    case .program: program = Int(value).clamped(to: 0...127)
    }

    if !updating {
      updateActivePreset()
    }
  }

  /**
   Obtain the current value of a parameter.

   - parameter parameter: the parameter to obtain
   - returns: the current value of the parameter
   */
  func get(_ parameter: AUParameter) -> AUValue {
    guard let address = AudioUnitParameters.Address(rawValue: parameter.address) else { return 0.0 }
    os_log(.info, log: log, "get - BEGIN: %d", parameter.address)
    let value: Int = {
      switch address {
      case .soundFont: return soundFont
      case .bank: return bank
      case .program: return program
      }
    }()
    os_log(.info, log: log, "get - END: %d", value)
    return AUValue(value)
  }
}

extension ParametersManager {

  /// Obtain the index of the sound font that is in use due to an active preset, or that is selected in the UI.
  private var soundFontIndex: Int? {
    guard
      let soundFontKey = self.activePresetManager.activeSoundFont?.key ?? selectedSoundFontManager.selected?.key
    else {
      return nil
    }
    return soundFonts.firstIndex(of: soundFontKey)
  }

  /// Obtain the active preset
  private var activePreset: Preset? { activePresetManager.activePreset }

  /**
   Change the parameters to match the currently active preset. This is only best-effort. If there is no active preset,
   the parameter values will all become 0.
   */
  private func reflectActivePreset() {
    os_log(.info, log: log, "reflectActivePreset - BEGIN")
    defer { updating = false }
    updating = true
    soundFont = soundFontIndex ?? 0
    audioUnitParameters.soundFont.value = AUValue(soundFont)
    bank = activePreset?.bank ?? 0
    audioUnitParameters.bank.value = AUValue(bank)
    program = activePreset?.program ?? 0
    audioUnitParameters.program.value = AUValue(program)
    os_log(.info, log: log, "reflectActivePreset - soundFont: %d bank: %d program: %d", soundFont, bank, program)
    os_log(.info, log: log, "reflectActivePreset - END")
  }

  /**
   Locate a preset that matches the current parameter settings. First, locates the sound font that corresponds to the
   current index value, and then search the presets of that sound font for the first one that has the current bank and
   program values.
   */
  private func updateActivePreset() {
    os_log(.info, log: log, "updateActivePreset - BEGIN", soundFont, bank, program)
    // Locate the sound font using the index
    let soundFontIndex = min(max(self.soundFont, 0), soundFonts.count - 1)
    guard soundFontIndex >= 0 else { return }

    let soundFont = soundFonts.getBy(index: soundFontIndex)
    if let preset = soundFont.presets.first(where: { $0.bank == bank && $0.program == program }) {
      activePresetManager.setActive(.preset(soundFontAndPreset: .init(soundFontKey: soundFont.key,
                                                                      presetIndex: preset.soundFontIndex,
                                                                      name: preset.presetConfig.name)))
    }
    os_log(.info, log: log, "updateActivePreset - END")
  }
}

