# Generated Tables

There are some lookup tables that are generated at compile time in order to speed up startup time. These tables are defined in
`DSPTables.hpp` and `MIDI/ValueTransformer.hpp`. There is a custom build phase for `SoundFontInfoLib` called
`Create DSPGenerated.cpp File` that generates this file. This works ok as long as a full rebuild is done.

The `Generated` folder points to
`DerivedData/SoundFonts/Build/Intermediates.noindex/SoundFontInfoLib.build/DerivedSources`. This is where the
`DSPGenerated.cpp` file will be found.

# Notes

This library parses valid SF2 files, extracting preset information and file metadata. The SoundFonts app and
AUv3 app extension use it to obtain the set of presets in the SF2 file. However, at present they rely on Apple's
AVAudioUnitSampler to deal with rendering audio from the presets. The ultimate goal is to do everything
ourselves, and there are some `render` classes to do just this.

## SF2 Format

A 'PHDR' sub-chunk defines a preset. Each one should have unique (wPreset, wBank) values. If the same, the first
one wins. if wPreset > 127 or wBank > 128 then technically it cannot be accessed via MIDI but it is still
considered valid.

A 'PBAG' sub-chunk defines the zones of the presets. A preset can have more than one. The first zone can be a
*global* zone if the last generator in the wGenNdx is *not* an Instrument generator. There cannot be a global
zone if there is only one zone for a preset. All zones but the first (global) zone must have at least one
generator (the Instrument generator). If a zone other than the first lacks an Instrument generator it should be
ignored. A global zone with no generators and no modulators should also be ignored.

A 'PMOD' (`sfModList` struct) sub-chunk defines a moderator in the preset zone. The `sfModDestOper` field
defines the destination of the modulation, usually an `SFGenerator`. If the MSB is 1 then it points to another
`sfModList` via an offset from the first moderator in the zone.

In SF2, there are *no* modulators, and the PMOD sub-chunk is always 10 bytes in length.

A 'PGEN' (`sfGenList` struct) sub-chunk defines a preset zone generator. Except for the global zone, the last
generator in a zone list *must* be an `instrument` generator.

A 'PGEN' value adjusts an instrument's generator; it never sets it directly except if the instrument's value is
zero.

If a key range generator is present it must be the first generator. If a velocity range generator is present, it
must be preceded by a key range generator (thus it must be the second generator).

An 'IBAG' sub-chunk defines the zones of an instrument. An instrument can have more than one. The first zone can
be a *global* zone if the last generator in the wGenNdx is *not* a `sampleID` generator. There cannot be a
global zone if there is only one zone for an instrument. All zones but the first (global) zone must have at
least one generator (the sample ID generator). If a zone other than the first lacks a sample ID generator it
should be ignored. A global zone with no generators and no modulators should also be ignored.

Modulates in 'IMOD' sub-chunk are absolute -- their values set a modulator instead of adjust it. But they always
adjust a generator.

In SF2, there are *no* modulators, and the IMOD sub-chunk is always 10 bytes in length.

There are three types of formats for values in PGEN and IGEN:

- range of MIDI key/velocity values (low and high)
- unsigned word index (16-bit)
- signed work value (16-bit)

If a key range generator is present it must be the first generator. If a velocity range generator is present, it
must be the first or second, and if second then the first must be a key range operator.

Generators that follow the `sampleID` generator are ignored.

# Kinds of Generators

- Index -- value is an index into another data structure
- Range -- key/velocity filter for determining if a zone applies to a note on event
- Substitution -- substitutes a value for a note-on parameter (two defined)
- Sample -- manipulates a sample property. Only defined for instrument not preset.
- Value -- a value that sets a signal processing parameter
