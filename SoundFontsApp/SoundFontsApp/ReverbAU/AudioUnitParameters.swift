// Changes: Copyright © 2020 Brad Howes. All rights reserved.
// Original: See LICENSE folder for this sample’s licensing information.

import AudioUnit
import SoundFontsFramework
import os

/// Definitions for the runtime parameters of the reverb.
public struct AudioUnitParameters {
  private let log = Logging.logger("AudioUnitParameters")

  /// Addresses for the individual AUParameter values
  enum Address: AUParameterAddress {
    /// Preset to use for the reverb
    case roomPreset = 1
    /// Amount of original signal vs reverb signal. Value of 0.0 is all original, value of 1.0 is all reverb.
    case wetDryMix
  }

  /// The AUParameter that controls the room preset that is in use.
  public let roomPreset: AUParameter = {
    let param = AUParameterTree.createParameter(
      withIdentifier: "room", name: "Room",
      address: Address.roomPreset.rawValue, min: 0.0,
      max: Float(ReverbEffect.roomNames.count - 1), unit: .indexed,
      unitName: nil,
      flags: [.flag_IsReadable, .flag_IsWritable], valueStrings: nil,
      dependentParameters: nil)
    param.value = 0.0
    return param
  }()

  /// The AUParameter that controls the mixture of the original and reverb signals.
  public let wetDryMix: AUParameter = {
    let param = AUParameterTree.createParameter(
      withIdentifier: "wetDryMix", name: "Mix",
      address: Address.wetDryMix.rawValue, min: 0.0, max: 100.0,
      unit: .percent,
      unitName: nil, flags: [.flag_IsReadable, .flag_IsWritable],
      valueStrings: nil, dependentParameters: nil)
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
    parameterTree = AUParameterTree.createTree(withChildren: [roomPreset, wetDryMix])
    parameterTree.implementorValueObserver = { parameterHandler.set($0, value: $1) }
    parameterTree.implementorValueProvider = { parameterHandler.get($0) }

    let log = self.log
    parameterTree.implementorStringFromValueCallback = { param, value in
      let formatted: String = {
        switch Address(rawValue: param.address) {
        case .roomPreset: return ReverbEffect.roomNames[Int(param.value)]
        case .wetDryMix: return String(format: "%.2f", param.value) + "%"
        default: return "?"
        }
      }()
      os_log(
        .info, log: log, "parameter %d as string: %d %f %{public}s",
        param.address, param.value, formatted)
      return formatted
    }
  }

  /**
   Apply a configuration to the reverb.

   - parameter config: the configuration to use
   */
  func setConfig(_ config: ReverbConfig) {
    os_log(.info, log: log, "setConfig")
    self.roomPreset.setValue(AUValue(config.preset), originator: nil)
    self.wetDryMix.setValue(config.wetDryMix, originator: nil)
  }

  /**
   Set a configuration parameter value.

   - parameter address: the parameter to change
   - parameter value: the new value for the parameter
   - parameter originator: a token from the source of the value change request
   */
  func set(_ address: Address, value: AUValue, originator: AUParameterObserverToken?) {
    switch address {
    case .roomPreset: roomPreset.setValue(value, originator: originator)
    case .wetDryMix: wetDryMix.setValue(value, originator: originator)
    }
  }
}

extension AUParameterTree {

  /**
   Obtain the current value of a configuration parameter.

   - parameter withAddress: the parameter to fetch
   - returns: the current value of the parameter
   */
  func parameter(withAddress: AudioUnitParameters.Address) -> AUParameter? {
    parameter(withAddress: withAddress.rawValue)
  }
}
