// Copyright © 2022 Brad Howes. All rights reserved.

import AudioUnit
import SoundFontsFramework
import os

/// Definitions for the runtime parameters of the audio unit.
public struct AudioUnitParameters {
  private let log = Logging.logger("AudioUnitParameters")

  enum Address: AUParameterAddress {
    case rater = 1
    case delay
    case depth
    case odd90
    case wetDryMix
  }

  public let rate: AUParameter = {
    let param = AUParameterTree.createParameter(
      withIdentifier: "rate", name: "Rate", address: Address.rate.rawValue, min: 0.1, max: 30.0, unit: .hertz,
      unitName: nil, flags: [.flag_IsReadable, .flag_IsWritable], valueStrings: nil, dependentParameters: nil)
    param.value = 1.0
    return param
  }()

  public let delay: AUParameter = {
    let param = AUParameterTree.createParameter(
      withIdentifier: "delay", name: "Delay", address: Address.delay.rawValue, min: 1, max: 30.0, unit: .milliseconds,
      unitName: nil, flags: [.flag_IsReadable, .flag_IsWritable], valueStrings: nil, dependentParameters: nil)
    param.value = 1.0
    return param
  }()

  public let depth: AUParameter = {
    let param = AUParameterTree.createParameter(
      withIdentifier: "depth", name: "Depth", address: Address.depth.rawValue, min: 1, max: 30, unit: .milliseconds,
      unitName: nil, flags: [.flag_IsReadable, .flag_IsWritable], valueStrings: nil, dependentParameters: nil)
    param.value = 30.0
    return param
  }()

  public let odd90: AUParameter = {
    let param = AUParameterTree.createParameter(
      withIdentifier: "odd90", name: "Odd90", address: Address.odd90.rawValue, min: 0.0, max: 1.0, unit: .boolean,
      unitName: nil, flags: [.flag_IsReadable, .flag_IsWritable], valueStrings: nil, dependentParameters: nil)
    param.value = 0.0
    return param
  }()

  public let wetDryMix: AUParameter = {
    let param = AUParameterTree.createParameter(
      withIdentifier: "wetDryMix", name: "Mix", address: Address.wetDryMix.rawValue, min: 0.0, max: 100.0,
      unit: .percent, unitName: nil, flags: [.flag_IsReadable, .flag_IsWritable], valueStrings: nil,
      dependentParameters: nil)
    param.value = 30.0
    return param
  }()

  /// AUParameterTree created with the parameter definitions for the audio unit
  public let parameterTree: AUParameterTree

  /**
   Create a new AUParameterTree for the defined filter parameters.

   Installs three closures in the tree:
   - one for providing values
   - one for accepting new values from other sources
   - and one for obtaining formatted string values

   - parameter parameterHandler the object to use to handle the AUParameterTree requests
   */
  public init(parameterHandler: AUParameterHandler) {

    // Define a new parameter tree with the parameter definitions
    parameterTree = AUParameterTree.createTree(withChildren: [time, feedback, cutoff, wetDryMix])

    // Provide a way for the tree to change values in the AudioUnit
    parameterTree.implementorValueObserver = parameterHandler.set

    // Provide a way for the tree to obtain the current value of a parameter from the AudioUnit
    parameterTree.implementorValueProvider = parameterHandler.get

    // Provide a way to obtain String values for the current settings.
    let log = self.log
    parameterTree.implementorStringFromValueCallback = { param, value in
      let formatted: String = {
        switch Address(rawValue: param.address) {
        case .rate: return String(format: "%.2f", param.value) + "Hz"
        case .delay: return String(format: "%f", param.value) + "ms"
        case .depth: return String(format: "%f", param.value) + "ms"
        case .odd90: return String(format: "%f", param.value)
        case .wetDryMix: return String(format: "%.2f", param.value) + "%"
        default: return "?"
        }
      }()
      os_log(.debug, log: log, "parameter %d as string: %d %f %{public}s", param.address, param.value, formatted)
      return formatted
    }
  }

  func setConfig(_ config: ChorusConfig) {
    os_log(.debug, log: log, "setConfig")
    self.rate.setValue(config.rate, originator: nil)
    self.delay.setValue(config.delay, originator: nil)
    self.depth.setValue(config.depth, originator: nil)
    self.odd90.setValue(config.odd90, originator: nil)
    self.wetDryMix.setValue(config.wetDryMix, originator: nil)
  }

  func set(_ address: Address, value: AUValue, originator: AUParameterObserverToken?) {
    switch address {
    case .rate: rate.setValue(value, originator: originator)
    case .delay: delay.setValue(value, originator: originator)
    case .depth: depth.setValue(value, originator: originator)
    case .odd90: odd90.setValue(value, originator: originator)
    case .wetDryMix: wetDryMix.setValue(value, originator: originator)
    }
  }
}

extension AUParameterTree {

  func parameter(withAddress: AudioUnitParameters.Address) -> AUParameter? {
    parameter(withAddress: withAddress.rawValue)
  }
}
