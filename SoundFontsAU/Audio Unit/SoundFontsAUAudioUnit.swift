// Copyright © 2020 Brad Howes. All rights reserved.

import Foundation
import AudioToolbox
import AVFoundation
import CoreAudioKit

public class SoundFontsAUAudioUnit: AUAudioUnit {

    private let parameters: SoundFontsAUParameters
    private let kernelAdapter: SoundFontsAUDSPKernelAdapter

    lazy private var inputBusArray: AUAudioUnitBusArray = {
        AUAudioUnitBusArray(audioUnit: self,
                            busType: .input,
                            busses: [kernelAdapter.inputBus])
    }()

    lazy private var outputBusArray: AUAudioUnitBusArray = {
        AUAudioUnitBusArray(audioUnit: self,
                            busType: .output,
                            busses: [kernelAdapter.outputBus])
    }()
    
    /// The units input busses
    public override var inputBusses: AUAudioUnitBusArray {
        return inputBusArray
    }

    /// The units output busses
    public override var outputBusses: AUAudioUnitBusArray {
        return outputBusArray
    }

    /// The tree of parameters provided by this AU.
    public override var parameterTree: AUParameterTree? {
        get {
            return parameters.parameterTree
        }
        set { }
    }

    public override init(componentDescription: AudioComponentDescription,
                         options: AudioComponentInstantiationOptions = []) throws {

        // Create adapter to communicate to underlying C++ DSP code
        kernelAdapter = SoundFontsAUDSPKernelAdapter()

        // Create parameters object to control paramOne
        parameters = SoundFontsAUParameters(kernelAdapter: kernelAdapter)
        
        // Init super class
        try super.init(componentDescription: componentDescription, options: options)

        // Log component description values
        log(componentDescription)
    }

    private func log(_ acd: AudioComponentDescription) {

        let info = ProcessInfo.processInfo
        print("\nProcess Name: \(info.processName) PID: \(info.processIdentifier)\n")

        let message = """
        SoundFontsAUDemo (
                  type: \(acd.componentType.stringValue)
               subtype: \(acd.componentSubType.stringValue)
          manufacturer: \(acd.componentManufacturer.stringValue)
                 flags: \(String(format: "%#010x", acd.componentFlags))
        )
        """
        print(message)
    }

    public override var maximumFramesToRender: AUAudioFrameCount {
        get {
            return kernelAdapter.maximumFramesToRender
        }
        set {
            if !renderResourcesAllocated {
                kernelAdapter.maximumFramesToRender = newValue
            }
        }
    }

    public override func allocateRenderResources() throws {

        if kernelAdapter.outputBus.format.channelCount == kernelAdapter.inputBus.format.channelCount {
        	try super.allocateRenderResources()

	        kernelAdapter.allocateRenderResources()
            return
        }

    	throw NSError(domain: NSOSStatusErrorDomain, code: Int(kAudioUnitErr_FormatNotSupported), userInfo: nil)
    }

    public override func deallocateRenderResources() {
        super.deallocateRenderResources()
        kernelAdapter.deallocateRenderResources()
    }

    public override var internalRenderBlock: AUInternalRenderBlock {
        return kernelAdapter.internalRenderBlock()
    }

    // Boolean indicating that this AU can process the input audio in-place
    // in the input buffer, without requiring a separate output buffer.
    public override var canProcessInPlace: Bool {
        return true
    }
}

extension FourCharCode {
    var stringValue: String {
        let value = CFSwapInt32BigToHost(self)
        let bytes = [0, 8, 16, 24].map { UInt8(value >> $0 & 0x000000FF) }
        guard let result = String(bytes: bytes, encoding: .macOSRoman) else {
            return "fail"
        }
        return result
    }
}
