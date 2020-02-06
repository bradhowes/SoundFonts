// Copyright © 2020 Brad Howes. All rights reserved.

import CoreAudioKit
import SoundFontsFramework

public class AudioUnitViewController: AUViewController, AUAudioUnitFactory {

    let sampler = Sampler(mode: .audiounit)
    var audioUnit: AUAudioUnit { return sampler.auAudioUnit }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    public func createAudioUnit(with componentDescription: AudioComponentDescription) throws -> AUAudioUnit {

        // audioUnit = try SoundFontAUAudioUnit(componentDescription: componentDescription, options: [])

        _ = sampler.start()
        return audioUnit
    }
}
