# Notes

This framework is a light-weight wrapper for the SF2Lib package that parses valid SF2 files, extracting preset
information and file metadata. The SoundFonts app and AUv3 app extension use it to obtain the set of presets in the SF2
file. However, at present they rely on Apple's AVAudioUnitSampler to deal with rendering audio from the presets. The
ultimate goal is to do everything ourselves, and there are some `render` classes to do just this. The SF2Lib package now
support this use-case as well, and the SoundFonts code is now transitioning away from the AVAudioUnitSampler class from
Apple.
