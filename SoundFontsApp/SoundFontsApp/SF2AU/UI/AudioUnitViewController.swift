//
//  AudioUnitViewController.swift
//  SF2SAU
//
//  Created by Brad Howes on 16/04/2022.
//  Copyright © 2022 Brad Howes. All rights reserved.
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
        audioUnit = try SF2AUAudioUnit(componentDescription: componentDescription, options: [])
        
        return audioUnit!
    }
    
}
