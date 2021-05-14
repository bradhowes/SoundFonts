#  ReverbAU

This is the AUv3 app extension which offers a reverb audio effect. This implementation relies on AVAudioUnitReverb to do the actual
signal processing. The extension has two runtime configuration properties:

- roomPreset -- an integer from 0-12 that refers to one of the room presets defined by AVAudioUnitReverb
- wetDryMix -- a floating-point value from 0.0 to 1.0 that controls how much of reverb signal to mix with the original signal.
A value of 0.0 results in only the original signal, while a value of 1.0 gives only reverb.


