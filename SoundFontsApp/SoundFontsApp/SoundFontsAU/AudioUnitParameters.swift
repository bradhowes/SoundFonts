// Changes: Copyright © 2020 Brad Howes. All rights reserved.
// Original: See LICENSE folder for this sample’s licensing information.

import AudioUnit
import SoundFontsFramework
import os

/// Definitions for the runtime parameters of the AU.
public final class AudioUnitParameters: NSObject {

  private let log = Logging.logger("FilterParameters")

  enum Address: AUParameterAddress {
    case undefined = 1
  }

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
  init(parameterHandler: AUParameterHandler) {

    // Define a new parameter tree with the parameter definitions
    parameterTree = AUParameterTree.createTree(withChildren: [])
    super.init()

    // Provide a way for the tree to change values in the AudioUnit
    parameterTree.implementorValueObserver = { parameterHandler.set($0, value: $1) }

    // Provide a way for the tree to obtain the current value of a parameter from the AudioUnit
    parameterTree.implementorValueProvider = { parameterHandler.get($0) }

    // Provide a way to obtain String values for the current settings.
    parameterTree.implementorStringFromValueCallback = { param, value in
      let formatted: String = {
        switch param.address {
        default: return "?"
        }
      }()
      os_log(
        .info, log: self.log, "parameter %d as string: %d %f %{public}s", param.address,
        param.value, formatted)
      return formatted
    }
  }
}
