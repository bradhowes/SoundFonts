//
//  AudioUnitViewController.swift
//  SoundFontsAU
//
//  Created by Brad Howes on 1/8/20.
//  Copyright © 2020 Brad Howes. All rights reserved.
//

import CoreAudioKit

public class AudioUnitViewController: AUViewController, AUAudioUnitFactory {
    var audioUnit: AUAudioUnit?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        if audioUnit == nil {
            return
        }
        
        // Get the parameter tree and add observers for any parameters that the UI needs to keep in sync with the AudioUnit
    }
    
    public func createAudioUnit(with componentDescription: AudioComponentDescription) throws -> AUAudioUnit {
        audioUnit = try SoundFontsAUAudioUnit(componentDescription: componentDescription, options: [])
        
        return audioUnit!
    }
    
}
