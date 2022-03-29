//
//  AudioUnitViewController.swift
//  Chorus
//
//  Created by Brad Howes on 27/03/2022.
//  Copyright © 2022 Brad Howes. All rights reserved.
//

import CoreAudioKit

public class ChorusViewController: AUViewController, AUAudioUnitFactory {
    var audioUnit: AUAudioUnit?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        if audioUnit == nil {
            return
        }
        
        // Get the parameter tree and add observers for any parameters that the UI needs to keep in sync with the AudioUnit
    }
    
    public func createAudioUnit(with componentDescription: AudioComponentDescription) throws -> AUAudioUnit {
        audioUnit = try ChorusAudioUnit(componentDescription: componentDescription, options: [])
        
        return audioUnit!
    }
    
}
