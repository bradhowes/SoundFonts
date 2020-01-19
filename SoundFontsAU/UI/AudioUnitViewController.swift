//
//  AudioUnitViewController.swift
//  SoundFontsAU
//
//  Created by Brad Howes on 1/8/20.
//  Copyright © 2020 Brad Howes. All rights reserved.
//

import CoreAudioKit
import SoundFontsFramework
import AVFoundation

public class AudioUnitViewController: AUViewController, AUAudioUnitFactory {

    private var sampler: AVAudioUnitSampler?

    public override func viewDidLoad() {
        super.viewDidLoad()
        guard let _ = sampler else { return }

        // Get the parameter tree and add observers for any parameters that the UI needs to keep in sync with the AudioUnit
    }
    
    public func createAudioUnit(with componentDescription: AudioComponentDescription) throws -> AUAudioUnit {
        let sampler = AVAudioUnitSampler(audioComponentDescription: componentDescription)
        self.sampler = sampler
        return sampler.auAudioUnit
    }
}
