//
//  AVSF2Engine.swift
//  SoundFontInfoLib
//
//  Created by Brad Howes on 17/04/2022.
//  Copyright © 2022 Brad Howes. All rights reserved.
//

import AVFAudio
import AUv3Support

public final class AVSF2Engine: AVAudioUnitMIDIInstrument {

  override public init() {
    let audioComponentDescription = AudioComponentDescription(componentType: FourCharCode("aumu"),
                                                              componentSubType: FourCharCode("sf2u"),
                                                              componentManufacturer: FourCharCode("bray"),
                                                              componentFlags: 0, componentFlagsMask: 0)
    super.init(audioComponentDescription: audioComponentDescription)
  }
}
