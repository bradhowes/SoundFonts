// Changes: Copyright © 2020 Brad Howes. All rights reserved.
// Original: See LICENSE folder for this sample’s licensing information.

import AudioUnit
import SoundFontsFramework
import os

/**
 Definitions for the runtime parameters of the filter. There are two:

 - cutoff -- the frequency at which the filter starts to roll off and filter out the higher frequencies
 - resonance -- a dB setting that can attenuate the frequencies near the cutoff

 */
public final class AudioUnitParameters: NSObject {

    private let log = Logging.logger("FilterParameters")

    enum Address: AUParameterAddress {
        case roomPreset = 1
        case wetDryMix
        case enabled
    }

    public let enabled: AUParameter = {
        let param = AUParameterTree.createParameter(withIdentifier: "enabled", name: "Enabled", address: Address.enabled.rawValue, min: 0.0, max: 1.0, unit: .boolean,
                                                    unitName: nil, flags: [.flag_IsReadable, .flag_IsWritable], valueStrings: nil, dependentParameters: nil)
        param.value = 1.0
        return param
    }()

    public let roomPreset: AUParameter = {
        let param = AUParameterTree.createParameter(withIdentifier: "room", name: "Room", address: Address.roomPreset.rawValue, min: 0.0,
                                                    max: Float(AppReverb.roomNames.count - 1), unit: .indexed, unitName: nil,
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
                case self.enabled.address: return String(format: "%.0f", param.value)
                case self.roomPreset.address: return AppReverb.roomNames[Int(param.value)]
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
        self.enabled.value = enabled
        self.roomPreset.value = roomPreset
        self.wetDryMix.value = wetDryMix
    }
}

extension AudioUnitParameters {

    var state: [String: Float] {
        let enabled = self.enabled.value
        let roomPreset = self.roomPreset.value
        let wetDryMix = self.wetDryMix.value
        return [self.enabled.identifier: enabled, self.roomPreset.identifier: roomPreset, self.wetDryMix.identifier: wetDryMix]
    }

    func setState(_ state: [String: Any]) {
        guard let enabled = state[self.enabled.identifier] as? Float else {
            os_log(.error, log: log, "missing '%s' in state", self.enabled.identifier)
            return
        }
        self.enabled.value = enabled

        guard let roomPreset = state[self.roomPreset.identifier] as? Float else {
            os_log(.error, log: log, "missing '%s' in state", self.roomPreset.identifier)
            return
        }
        self.roomPreset.value = roomPreset

        guard let wetDryMix = state[self.wetDryMix.identifier] as? Float else {
            os_log(.error, log: log, "missing '%s' in state", self.wetDryMix.identifier)
            return
        }
        self.wetDryMix.value = wetDryMix

        os_log(.info, log: log, "setState - roomPreset: %f wetDryMix: %f", roomPreset, wetDryMix)
    }

    func matches(_ state: [String: Any]) -> Bool {
        for (key, value) in self.state {
            guard let other = state[key] as? Float, other == value else { return false }
        }
        return true
    }
}