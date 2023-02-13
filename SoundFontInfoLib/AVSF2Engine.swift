// Copyright © 2022 Brad Howes. All rights reserved.

import AVFAudio

/**
 Engine that uses SF2EngineAU wrapper to render sounds.
 */
public final class AVSF2Engine {
  public let avAudioUnit: AVAudioUnitMIDIInstrument
  public let sf2Engine: SF2EngineAU

  public var synthGain: Float = 1.0
  public var synthStereoPan: Float = 0.0
  public var synthGlobalTuning: Float = 0.0
  public var midiChannel: Int = 0

  public init() {
    self.avAudioUnit = Self.instantiate()
    guard let sf2Engine = avAudioUnit.auAudioUnit as? SF2EngineAU else { fatalError() }
    self.sf2Engine = sf2Engine
  }

  /// The component description for SF2EngineAU
  public static let audioComponentDescription = AudioComponentDescription(componentType: FourCharCode("aumu"),
                                                                          componentSubType: FourCharCode("sf2e"),
                                                                          componentManufacturer: FourCharCode("bray"),
                                                                          componentFlags: 0, componentFlagsMask: 0)

  /**
   Attempt to asynchronously create a new SF2EngineAU instance.

   - parameter completionHandler: the block to invoke after the creation attempt
   */
  public static func instantiate(completionHandler: @escaping (AVAudioUnit?, Error?) -> Void) {
    AUAudioUnit.registerSubclass(SF2EngineAU.self, as: AVSF2Engine.audioComponentDescription, name: "SF2Engine",
                                 version: 1)
    AVAudioUnit.instantiate(with: audioComponentDescription, completionHandler: completionHandler)
  }

  /**
   Attempt to create a new SF2EngineAU instance wrapped in an AVAudioUnitMIDIInstrument AV audio unit. Note that this
   implementation calls `fatalError` if unable to create an instance.

   - returns: AVAudioUnitMIDIInstrument that holds an SF2EngineAU instance.
   */
  public static func instantiate() -> AVAudioUnitMIDIInstrument {
    let semaphore = DispatchSemaphore(value: 0)
    var result: AVAudioUnitMIDIInstrument!
    instantiate { avAudioUnit, _ in
      guard let avAudioUnit = avAudioUnit as? AVAudioUnitMIDIInstrument else {
        fatalError("Unable to instantiate SF2EngineAU")
      }
      result = avAudioUnit
      semaphore.signal()
    }
    _ = semaphore.wait(wallTimeout: .distantFuture)
    return result
  }
}
