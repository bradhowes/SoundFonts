// Changes: Copyright © 2020 Brad Howes. All rights reserved.
// Original: See LICENSE folder for this sample’s licensing information.

import AudioUnit
import SoundFontsFramework
import os

/// Definitions for the runtime parameters of the AU.
public final class AudioUnitParameters: NSObject {
  private lazy var log = Logging.logger("AudioUnitParameters")

  public enum Address: AUParameterAddress {
    case soundFont = 1
    case bank = 2
    case program = 3
  }

  public let soundFont = AUParameterTree.createParameter(withIdentifier: "soundFont", name: "SoundFont",
                                                         address: Address.soundFont.rawValue,
                                                         min: 0, max: 127,
                                                         unit: .midiController,
                                                         unitName: nil,
                                                         flags: [.flag_IsReadable, .flag_IsWritable],
                                                         valueStrings: nil,
                                                         dependentParameters: nil)

  public let bank = AUParameterTree.createParameter(withIdentifier: "bank", name: "Bank",
                                                    address: Address.bank.rawValue,
                                                    min: 0, max: 127,
                                                    unit: .midiController,
                                                    unitName: nil,
                                                    flags: [.flag_IsReadable, .flag_IsWritable],
                                                    valueStrings: nil,
                                                    dependentParameters: nil)

  public let program = AUParameterTree.createParameter(withIdentifier: "program", name: "Program",
                                                       address: Address.program.rawValue,
                                                       min: 0, max: 127,
                                                       unit: .midiController,
                                                       unitName: nil,
                                                       flags: [.flag_IsReadable, .flag_IsWritable],
                                                       valueStrings: nil,
                                                       dependentParameters: nil)

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
    parameterTree = AUParameterTree.createTree(withChildren: [soundFont, bank, program])
    super.init()

    // Provide a way for the tree to change values in the AudioUnit
    parameterTree.implementorValueObserver = { parameterHandler.set($0, value: $1) }

    // Provide a way for the tree to obtain the current value of a parameter from the AudioUnit
    parameterTree.implementorValueProvider = { parameterHandler.get($0) }

    // Provide a way to obtain String values for the parameter settings.
    parameterTree.implementorStringFromValueCallback = { param, _ in
      guard let address = Address(rawValue: param.address) else { return "" }
      switch address {
      case .soundFont: return "\(param.value)"
      case .bank: return "\(param.value)"
      case .program: return "\(param.value)"
      }
    }
  }
}
