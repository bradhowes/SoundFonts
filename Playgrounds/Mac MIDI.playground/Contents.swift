import PlaygroundSupport
import Foundation
import AVFoundation

extension Double {
    public var milliseconds: TimeInterval { self / 1000 }
    public var millisecond: TimeInterval { milliseconds }
    public var ms: TimeInterval { milliseconds }

    public var seconds: TimeInterval { self }
    public var second: TimeInterval { seconds }

    public var minutes: TimeInterval { seconds * 60 }
    public var minute: TimeInterval { minutes }

    public var hours: TimeInterval { minutes * 60 }
    public var hour: TimeInterval { hours }

    public var days: TimeInterval { hours * 24 }
    public var day: TimeInterval { days }
}

extension DispatchTime {
    static func future(_ delta: DispatchTimeInterval) -> DispatchTime { DispatchTime.now() + delta }
}

let url = URL(fileURLWithPath: "Users/howes/src/Mine/SoundFonts/SF2Files/Resources/FreeFont.sf2")
let data = try! Data(contentsOf: url)
let engine = AVAudioEngine()
let sampler = AVAudioUnitSampler()
let reverb = AVAudioUnitReverb()
let delay = AVAudioUnitDelay()

engine.attach(sampler)
engine.attach(reverb)
engine.attach(delay)

let output = engine.mainMixerNode
engine.connect(reverb, to: output, format: nil)
engine.connect(delay, to: reverb, format: nil)
engine.connect(sampler, to: delay, format: nil)
do {
    try engine.start()
    try sampler.loadSoundBankInstrument(at: url, program: 0, bankMSB: 0, bankLSB: 1)
} catch {
    print(error)
}

reverb.loadFactoryPreset(.cathedral)
reverb.wetDryMix = 50.0

delay.delayTime = 1.0
delay.feedback = 50.0
delay.lowPassCutoff = 18000.0
delay.wetDryMix = 50.0

let noteOn = DispatchWorkItem { sampler.startNote(64, withVelocity: 127, onChannel: 0) }
let noteOff = DispatchWorkItem { sampler.stopNote(64, onChannel: 0) }
let done = DispatchWorkItem { PlaygroundPage.current.finishExecution() }

DispatchQueue.global(qos: .background).asyncAfter(deadline: DispatchTime.now() + 0.15.seconds, execute: noteOn)
DispatchQueue.global(qos: .background).asyncAfter(deadline: DispatchTime.now() + 0.65.seconds, execute: noteOff)
DispatchQueue.global(qos: .background).asyncAfter(deadline: DispatchTime.now() + 5.0.seconds, execute: done)

PlaygroundPage.current.needsIndefiniteExecution = true

