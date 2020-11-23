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
        case time = 1
        case feedback
        case cutoff
        case wetDryMix
        case enabled
    }

    public let enabled: AUParameter = {
        let param = AUParameterTree.createParameter(withIdentifier: "enabled", name: "Enabled", address: Address.enabled.rawValue, min: 0.0, max: 1.0, unit: .boolean,
                                                    unitName: nil, flags: [.flag_IsReadable, .flag_IsWritable], valueStrings: nil, dependentParameters: nil)
        param.value = 1.0
        return param
    }()

    public let time: AUParameter = {
        let param = AUParameterTree.createParameter(withIdentifier: "time", name: "Time", address: Address.time.rawValue, min: 0.0, max: 2.0, unit: .seconds,
                                                    unitName: nil, flags: [.flag_IsReadable, .flag_IsWritable], valueStrings: nil, dependentParameters: nil)
        param.value = 1.0
        return param
    }()

    public let feedback: AUParameter = {
        let param = AUParameterTree.createParameter(withIdentifier: "feedback", name: "Feedback", address: Address.feedback.rawValue, min: -50.0, max: 100.0,
                                                    unit: .percent, unitName: nil, flags: [.flag_IsReadable, .flag_IsWritable], valueStrings: nil, dependentParameters: nil)
        param.value = 50.0
        return param
    }()

    public let cutoff: AUParameter = {
        let param = AUParameterTree.createParameter(withIdentifier: "cutoff", name: "Cutoff", address: Address.cutoff.rawValue,  min: 12.0, max: 20_000.0,
                                                    unit: .hertz, unitName: nil, flags: [.flag_IsReadable, .flag_IsWritable], valueStrings: nil, dependentParameters: nil)
        param.value = 18_000.0
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
        parameterTree = AUParameterTree.createTree(withChildren: [time, feedback, cutoff, wetDryMix, enabled])
        super.init()

        // Provide a way for the tree to change values in the AudioUnit
        parameterTree.implementorValueObserver = parameterHandler.set

        // Provide a way for the tree to obtain the current value of a parameter from the AudioUnit
        parameterTree.implementorValueProvider = parameterHandler.get

        // Provide a way to obtain String values for the current settings.
        parameterTree.implementorStringFromValueCallback = { param, value in
            let formatted: String = {
                switch param.address {
                case self.enabled.address: return String(format: "%.0f", param.value)
                case self.time.address: return String(format: "%.2f", param.value) + "s"
                case self.feedback.address: return String(format: "%.2f", param.value) + "%"
                case self.cutoff.address: return String(format: "%.2f", param.value) + "Hz"
                case self.wetDryMix.address: return String(format: "%.2f", param.value) + "%"
                default: return "?"
                }
            }()
            os_log(.info, log: self.log, "parameter %d as string: %d %f %{public}s", param.address, param.value, formatted)
            return formatted
        }
    }

    /**
     Accept new values for the filter settings. Uses the AUParameterTree framework for communicating the changes to the
     AudioUnit.

     - parameter cutoffValue: the new cutoff value to use
     - parameter resonanceValue: the new resonance value to use
     */
    func setParameterValues(enabled: AUValue, time: AUValue, feedback: AUValue, cutoff: AUValue, wetDryMix: AUValue) {
        os_log(.info, log: log, "setParameterValues")
        self.enabled.value = enabled
        self.time.value = time
        self.feedback.value = feedback
        self.cutoff.value = cutoff
        self.wetDryMix.value = wetDryMix
    }
}
