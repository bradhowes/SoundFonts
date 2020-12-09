// Changes: Copyright © 2020 Brad Howes. All rights reserved.
// Original: See LICENSE folder for this sample’s licensing information.

import AudioUnit
import SoundFontsFramework
import os

/**
 Definitions for the runtime parameters of the reverb.
 */
public final class AudioUnitParameters: NSObject {

    private let log = Logging.logger("ReverbParameters")

    enum Address: AUParameterAddress {
        case roomPreset = 1
        case wetDryMix
    }

    public let roomPreset: AUParameter = {
        let param = AUParameterTree.createParameter(withIdentifier: "room", name: "Room", address: Address.roomPreset.rawValue, min: 0.0,
                                                    max: Float(Reverb.roomNames.count - 1), unit: .indexed, unitName: nil,
                                                    flags: [.flag_IsReadable, .flag_IsWritable], valueStrings: nil, dependentParameters: nil)
        param.value = 0.0
        return param
    }()

    public let wetDryMix: AUParameter = {
        let param = AUParameterTree.createParameter(withIdentifier: "wetDryMix", name: "Mix", address: Address.wetDryMix.rawValue, min: 0.0, max: 100.0, unit: .percent,
                                                    unitName: nil, flags: [.flag_IsReadable, .flag_IsWritable], valueStrings: nil, dependentParameters: nil)
        param.value = 30.0
        return param
    }()

    /// AUParameterTree created with the parameter defintions for the audio unit
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

        // Define a new parameter tree with the parameter defintions
        parameterTree = AUParameterTree.createTree(withChildren: [roomPreset, wetDryMix])
        super.init()

        // Provide a way for the tree to change values in the AudioUnit
        parameterTree.implementorValueObserver = { parameterHandler.set($0, value: $1) }

        // Provide a way for the tree to obtain the current value of a parameter from the AudioUnit
        parameterTree.implementorValueProvider = { parameterHandler.get($0) }

        // Provide a way to obtain String values for the current settings.
        parameterTree.implementorStringFromValueCallback = { param, value in
            let formatted: String = {
                switch param.address {
                case self.roomPreset.address: return Reverb.roomNames[Int(param.value)]
                case self.wetDryMix.address: return String(format: "%.2f", param.value) + "%"
                default: return "?"
                }
            }()
            os_log(.info, log: self.log, "parameter %d as string: %d %f %{public}s",
                   param.address, param.value, formatted)
            return formatted
        }
    }

    /**
     Accept new values for the filter settings. Uses the AUParameterTree framework for communicating the changes to the
     AudioUnit.

     - parameter cutoffValue: the new cutoff value to use
     - parameter resonanceValue: the new resonance value to use
     */
    func setParameterValues(enabled: AUValue, roomPreset: AUValue, wetDryMix: AUValue) {
        self.roomPreset.value = roomPreset
        self.wetDryMix.value = wetDryMix
    }

    func set(_ address: Address, value: AUValue, originator: AUParameterObserverToken?) {
        switch address {
        case .roomPreset: self.roomPreset.setValue(value, originator: originator)
        case .wetDryMix: self.wetDryMix.setValue(value, originator: originator)
        }
    }
}
