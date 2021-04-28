// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "Types.hpp"
#include "IO/Pos.hpp"
#include "IO/StringUtils.hpp"

namespace SF2 {
namespace Entity {

/**
 Define the audio samples to be used for playing a specific sound.

 Memory layout of a 'shdr' entry. The size of this is defined to be 46 bytes, but due
 to alignment/padding the struct below is 48 bytes.

 The offsets (begin, end, loopBegin, and loopEnd) are indices into a big array of 16-bit integer sample values.
 */
class SampleHeader {
public:
    constexpr static size_t size = 46;

    enum Type {
        monoSample = 1,
        rightSample = 2,
        leftSample = 4,
        linkedSample = 8,
        rom = 0x8000
    };

    /**
     Construct new instance from SF2 file
     */
    explicit SampleHeader(IO::Pos& pos)
    {
        assert(sizeof(*this) == size + 2);
        pos = pos.readInto(&achSampleName, 40);
        pos = pos.readInto(&originalKey, 6);
        IO::trim_property(achSampleName);
    }

    /**
     Construct instance for unit tests.
     */
    SampleHeader(uint32_t start, uint32_t end, uint32_t loopBegin, uint32_t loopEnd,
                 uint32_t sampleRate, uint8_t key, int8_t adjustment)
    : dwStart{start}, dwEnd{end}, dwStartLoop{loopBegin}, dwEndLoop{loopEnd}, dwSampleRate{sampleRate},
    originalKey{key}, correction{adjustment} {}

    /// @returns true if this sample only has one channel
    bool isMono() const { return (sampleType & monoSample) == monoSample; }

    /// @returns true if these samples generate for the right channel
    bool isRight() const { return (sampleType & rightSample) == rightSample; }

    /// @returns true if these samples generate for the left channel
    bool isLeft() const { return (sampleType & leftSample) == leftSample; }

    /// @returns true if samples come from a ROM
    bool isROM() const { return (sampleType & rom) == rom; }

    /// @returns the index of the first sample
    size_t startIndex() const { return dwStart; }

    /// @returns index + 1 of the last sample. According to spec, this is first of 46 0.0 values after the last sample
    size_t endIndex() const { return dwEnd; }

    /// @returns index of the first sample in a loop.
    size_t startLoopIndex() const { return dwStartLoop; }

    /// @returns index of the last + 1 of a sample in a loop.
    size_t endLoopIndex() const { return dwEndLoop; }

    /// @returns the sample rate used to record the samples in the SF2 file
    size_t sampleRate() const { return dwSampleRate; }

    /// @returns the MIDI key (frequency) for the source samples
    Int originalMIDIKey() const { return originalKey; }

    /// @returns the pitch correction to apply when playing back the samples
    Int pitchCorrection() const { return correction; }

    void dump(const std::string& indent, int index) const;

private:
    std::string sampleTypeDescription() const;

    char achSampleName[20];
    uint32_t dwStart;
    uint32_t dwEnd;
    uint32_t dwStartLoop;
    uint32_t dwEndLoop;
    uint32_t dwSampleRate;
    // *** PADDING ***
    uint8_t originalKey;
    int8_t correction;
    uint16_t sampleLink;
    uint16_t sampleType;
};

} // end namespace Entity
} // end namespace SF2
