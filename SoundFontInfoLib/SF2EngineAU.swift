// Copyright © 2020 Brad Howes. All rights reserved.

import AudioToolbox
import CoreAudioKit
import os

/**
 AUv3 component for SF2Engine.
 */
public final class SF2EngineAU: AUAudioUnit {
  private let log: OSLog
  private var _audioUnitName: String?
  private var _audioUnitShortName: String?
  private var _currentPreset: AUAudioUnitPreset?

  public let engine: SF2Engine

  /// Maximum frames to render
  private let maxFramesToRender: UInt32 = 512

  private var dryBus: AUAudioUnitBus!
  private var chorusSendBus: AUAudioUnitBus!
  private var reverbSendBus: AUAudioUnitBus!

  // We have no inputs
  private lazy var _inputBusses: AUAudioUnitBusArray =
  AUAudioUnitBusArray(audioUnit: self, busType: .input, busses: [])

  // We have three outputs -- dry, chorus, reverb
  private lazy var _outputBusses: AUAudioUnitBusArray =
  AUAudioUnitBusArray(audioUnit: self, busType: .output, busses: [dryBus!, chorusSendBus!, reverbSendBus!])

  public override var inputBusses: AUAudioUnitBusArray { return _inputBusses }
  public override var outputBusses: AUAudioUnitBusArray { return _outputBusses }

  public enum Failure: Error {
    case invalidFormat
    case creatingBus(name: String)
  }

  /**
   Construct a new AUv3 component.

   - parameter componentDescription: the definition used when locating the component to create
   */
  public override init(componentDescription: AudioComponentDescription,
                       options: AudioComponentInstantiationOptions = []) throws {
    let loggingSubsystem = "com.braysoftware.SoundFonts"
    let log = OSLog(subsystem: loggingSubsystem, category: "SF2EngineAU")
    self.log = log
    self.engine = SF2Engine(loggingBase: loggingSubsystem, voiceCount: 32)

    os_log(.debug, log: log, "init - flags: %d man: %d type: sub: %d", componentDescription.componentFlags,
           componentDescription.componentManufacturer, componentDescription.componentType,
           componentDescription.componentSubType)

    os_log(.debug, log: log, "super.init")
    do {
      try super.init(componentDescription: componentDescription, options: options)
    } catch {
      os_log(.error, log: log, "failed to initialize AUAudioUnit - %{public}s", error.localizedDescription)
      throw error
    }

    guard let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 44100, channels: 2,
                                     interleaved: false) else {
      throw Failure.invalidFormat
    }

    maximumFramesToRender = maxFramesToRender

    dryBus = try createBus(name: "dry", format: format)
    chorusSendBus = try createBus(name: "chorusSend", format: format)
    reverbSendBus = try createBus(name: "reverbSend", format: format)

    os_log(.debug, log: log, "init - done")
  }

  public func load(_ url: URL) { engine.load(url) }

  public func selectPreset(_ index: Int32) { engine.selectPreset(index) }

  public func noteOn(_ key: Int32, velocity: Int32) { engine.note(on: key, velocity: velocity) }

  public func noteOff(_ key: Int32) { engine.noteOff(key) }
}

extension SF2EngineAU {

  private func createBus(name: String, format: AVAudioFormat) throws -> AUAudioUnitBus {
    do {
      let bus = try AUAudioUnitBus(format: format)
      bus.name = name
      return bus
    } catch {
      os_log(.error, log: log, "failed to create %{public}s bus - %{public}s", error.localizedDescription)
      throw Failure.creatingBus(name: name)
    }
  }

  private func updateShortName() {
    let presetName = engine.presetName.trimmingCharacters(in: .whitespaces)
    self.audioUnitShortName = presetName.isEmpty ? "----" : presetName
  }
}

extension SF2EngineAU {

  public override var audioUnitName: String? {
    get { _audioUnitName }
    set {
      os_log(.debug, log: log, "audioUnitName set - %{public}s", newValue ?? "???")
      willChangeValue(forKey: "audioUnitName")
      _audioUnitName = newValue
      didChangeValue(forKey: "audioUnitName")
    }
  }

  public override var audioUnitShortName: String? {
    get { _audioUnitShortName }
    set {
      os_log(.debug, log: log, "audioUnitShortName set - %{public}s", newValue ?? "???")
      willChangeValue(forKey: "audioUnitShortName")
      _audioUnitShortName = newValue
      didChangeValue(forKey: "audioUnitShortName")
    }
  }

  public override func supportedViewConfigurations(_ viewConfigs: [AUAudioUnitViewConfiguration]) -> IndexSet {
    os_log(.debug, log: log, "supportedViewConfigurations")
    let indices = viewConfigs.enumerated().compactMap {
      $0.1.height > 270 ? $0.0 : nil
    }
    os_log(.debug, log: log, "indices: %{public}s", indices.debugDescription)
    return IndexSet(indices)
  }

  public override func allocateRenderResources() throws {
    os_log(.debug, log: log, "allocateRenderResources BEGIN - outputBusses: %{public}d", outputBusses.count)

    let format = dryBus.format
    engine.setRenderingFormat(3, format: format, maxFramesToRender: maximumFramesToRender)

    for index in 0..<outputBusses.count {
      outputBusses[index].shouldAllocateBuffer = true
    }

    do {
      try super.allocateRenderResources()
    } catch {
      os_log(.error, log: log, "allocateRenderResources failed - %{public}s", error.localizedDescription)
      throw error
    }

    os_log(.debug, log: log, "allocateRenderResources END")
  }

  public override func deallocateRenderResources() {
    os_log(.debug, log: log, "deallocateRenderResources")
    super.deallocateRenderResources()
  }

  // We do not process input
  public override var canPerformInput: Bool { false }

  // We do generate output
  public override var canPerformOutput: Bool { true }

  public override var internalRenderBlock: AUInternalRenderBlock { engine.internalRenderBlock() }
}

// MARK: - State Management

extension SF2EngineAU {

  private var activeSoundFontPresetKey: String { "soundFontPatch" } // Legacy name -- do not change

  public override var fullState: [String: Any]? {
    get {
      os_log(.debug, log: log, "fullState GET")
      var state = [String: Any]()
      addInstanceSettings(into: &state)
      return state
    }
    set {
      os_log(.debug, log: log, "fullState SET")
      if let state = newValue {
        restoreInstanceSettings(from: state)
      }
    }
  }

  /**
   Save into a state dictionary the settings that are really part of an AUv3 instance

   - parameter state: the storage to hold the settings
   */
  private func addInstanceSettings(into state: inout [String: Any]) {
    os_log(.debug, log: log, "addInstanceSettings BEGIN")

//    if let dict = self.activePresetManager.active.encodeToDict() {
//      state[activeSoundFontPresetKey] = dict
//    }
//
//    state[SettingKeys.activeTagKey.key] = settings.activeTagKey.uuidString
//    state[SettingKeys.globalTuning.key] = settings.globalTuning
//    state[SettingKeys.pitchBendRange.key] = settings.pitchBendRange
//    state[SettingKeys.presetsWidthMultiplier.key] = settings.presetsWidthMultiplier
//    state[SettingKeys.showingFavorites.key] = settings.showingFavorites

    os_log(.debug, log: log, "addInstanceSettings END")
  }

  /**
   Restore from a state dictionary the settings that are really part of an AUv3 instance

   - parameter state: the storage that holds the settings
   */
  private func restoreInstanceSettings(from state: [String: Any]) {
    os_log(.debug, log: log, "restoreInstanceSettings BEGIN")

//    settings.setAudioUnitState(state)
//
//    let value: ActivePresetKind = {
//      // First try current representation as a dict
//      if let dict = state[activeSoundFontPresetKey] as? [String: Any],
//         let value = ActivePresetKind.decodeFromDict(dict) {
//        return value
//      }
//      // Fall back and try Data encoding
//      if let data = state[activeSoundFontPresetKey] as? Data,
//         let value = ActivePresetKind.decodeFromData(data) {
//        return value
//      }
//      // Nothing known.
//      return .none
//    }()
//
//    self.activePresetManager.restoreActive(value)
//
//    if let activeTagKeyString = state[SettingKeys.activeTagKey.key] as? String,
//       let activeTagKey = UUID(uuidString: activeTagKeyString) {
//      settings.activeTagKey = activeTagKey
//    }

    os_log(.debug, log: log, "restoreInstanceSettings END")
  }
}

// MARK: - User Presets Management

extension SF2EngineAU {

  public override var supportsUserPresets: Bool { true }

  /**
   Notification that the `currentPreset` attribute of the AudioUnit has changed. These should be user presets created
   by a host application. The host can then change the current preset and we need to react to this change by updating
   the active preset value. We do this as a side-effect of setting the `fullState` attribute with the state for the
   give user preset.

   - parameter preset: the new value of `currentPreset`
   */
//  private func currentPresetChanged(_ preset: AUAudioUnitPreset?) {
//    guard let preset = preset else { return }
//    os_log(.debug, log: log, "currentPresetChanged BEGIN - %{public}s", preset)
//
//    // There are no factory presets (should there be?) so this only applies to user presets.
//    guard preset.number < 0 else  { return }
//
//    if #available(iOS 13.0, *) {
//      guard let state = try? wrapped.presetState(for: preset) else { return }
//      os_log(.debug, log: log, "state: %{public}s", state.debugDescription)
//      fullState = state
//    }
//  }

  public override var currentPreset: AUAudioUnitPreset? {
    get { _currentPreset }
    set {
      guard let preset = newValue else {
        _currentPreset = nil
        return
      }

      _currentPreset = preset

      if preset.number < 0 {
        if #available(iOS 13.0, *) {
          if let fullState = try? presetState(for: preset) {
            self.fullState = fullState
          }
        }
      }
    }
  }
}
