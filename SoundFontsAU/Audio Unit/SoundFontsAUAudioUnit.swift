// Copyright © 2020 Brad Howes. All rights reserved.

import Foundation
import AudioToolbox
import AVFoundation
import CoreAudioKit
import SoundFontsFramework

public class SoundFontsAUAudioUnit: AUAudioUnit {

    public override var inputBusses: AUAudioUnitBusArray { auSampler.inputBusses }
    public override var outputBusses: AUAudioUnitBusArray { auSampler.outputBusses }
    public override var parameterTree: AUParameterTree? { get { nil } set {} }
    public override var renderResourcesAllocated: Bool { auSampler.renderResourcesAllocated }
    public override var isMusicDeviceOrEffect: Bool { auSampler.isMusicDeviceOrEffect }
    public override var virtualMIDICableCount: Int { auSampler.virtualMIDICableCount }

    public override var latency: TimeInterval { auSampler.latency }
    public override var tailTime: TimeInterval { auSampler.tailTime }
    public override var renderQuality: Int {
        get { auSampler.renderQuality }
        set { auSampler.renderQuality = newValue }
    }
    public override var internalRenderBlock: AUInternalRenderBlock { auSampler.internalRenderBlock }
    public override var canProcessInPlace: Bool { auSampler.canProcessInPlace }
    public override var isRenderingOffline: Bool {
        get { auSampler.isRenderingOffline }
        set { auSampler.isRenderingOffline = newValue }
    }

    public override var channelCapabilities: [NSNumber]? { auSampler.channelCapabilities }

    public override init(componentDescription: AudioComponentDescription,
                         options: AudioComponentInstantiationOptions = []) throws {
        try super.init(componentDescription: componentDescription, options: options)

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
        get { auSampler.maximumFramesToRender }
        set {
            if !renderResourcesAllocated {
                auSampler.maximumFramesToRender = newValue
            }
        }
    }

    public override func allocateRenderResources() throws {
        try auSampler.allocateRenderResources()
    }

    public override func deallocateRenderResources() {
        super.deallocateRenderResources()
        auSampler.deallocateRenderResources()
    }

    public override func reset() {
        auSampler.reset()
        super.reset()
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
