// Copyright © 2022 Brad Howes. All rights reserved.

import AVFAudio
import AUv3Support

/**
 An enum masquerading as a namespace. Originally this was a class derived from `AVAudioUnitMIDIInstrument`, but there
 is no way to instantiate a class like that from within the AV framework. Instead, the component description indicates
 the `AV*` class one will get for an audio unit via the `componentType` attribute. For type `aumu` this will be an
 `AVAudioUnitMIDIInstrument` instance, while for an audio effect (type `aufx`) this will be an `AVAudioUnit` instance.
 */
public enum AVSF2Engine {
  public static let audioComponentDescription = AudioComponentDescription(componentType: FourCharCode("aumu"),
                                                                          componentSubType: FourCharCode("sf2e"),
                                                                          componentManufacturer: FourCharCode("bray"),
                                                                          componentFlags: 0, componentFlagsMask: 0)
}
