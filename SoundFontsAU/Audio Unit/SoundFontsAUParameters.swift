//
//  SoundFontsAUParameters.swift
//  SoundFontsAU
//
//  Created by Brad Howes on 1/8/20.
//  Copyright © 2020 Brad Howes. All rights reserved.
//

import Foundation
import AudioToolbox

/// Manages the SoundFontsAU object's paramOne.
class SoundFontsAUParameters {

    private enum SoundFontsAUParam: AUParameterAddress {
        case paramOne
    }

    /// Example parameter
    var paramOne: AUParameter = {
        let parameter =
            AUParameterTree.createParameter(withIdentifier: "paramOne",
                                            name: "paramOne",
                                            address: SoundFontsAUParam.paramOne.rawValue,
                                            min: 0.0,
                                            max: 100.0,
                                            unit: .percent,
                                            unitName: nil,
                                            flags: [.flag_IsReadable,
                                                    .flag_IsWritable],
                                            valueStrings: nil,
                                            dependentParameters: nil)
        // Set default value
        parameter.value = 50.0

        return parameter
    }()

    let parameterTree: AUParameterTree

    init(kernelAdapter: SoundFontsAUDSPKernelAdapter) {

        // Create the audio unit's tree of parameters
        parameterTree = AUParameterTree.createTree(withChildren: [paramOne])

        // Closure observing all externally-generated parameter value changes.
        parameterTree.implementorValueObserver = { param, value in
            kernelAdapter.setParameter(param, value: value)
        }

        // Closure returning state of requested parameter.
        parameterTree.implementorValueProvider = { param in
            return kernelAdapter.value(for: param)
        }

        // Closure returning string representation of requested parameter value.
        parameterTree.implementorStringFromValueCallback = { param, value in
            switch param.address {
            case SoundFontsAUParam.paramOne.rawValue:
                return String(format: "%.f", value ?? param.value)
            default:
                return "?"
            }
        }
    }
}
