// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <iostream>

#include "Types.hpp"
#include "IO/Pos.hpp"
#include "IO/StringUtils.hpp"

namespace SF2 {
namespace Entity {

/**
 Define the audio samples to be used for playing a specific sound.

 Memory layout of a 'shdr' entry. The size of this is defined to be 46 bytes, but due
 to alignment/padding the struct below is 48 bytes.
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

    explicit SampleHeader(IO::Pos& pos)
    {
        assert(sizeof(*this) == size + 2);
        pos = pos.readInto(&achSampleName, 40);
        pos = pos.readInto(&originalKey, 6);
        IO::trim_property(achSampleName);
    }

    SampleHeader(uint32_t start, uint32_t end, uint32_t loopBegin, uint32_t loopEnd,
                 uint32_t sampleRate, uint8_t key, int8_t adjustment)
    : dwStart{start}, dwEnd{end}, dwStartLoop{loopBegin}, dwEndLoop{loopEnd}, dwSampleRate{sampleRate},
    originalKey{key}, correction{adjustment} {}

    bool isMono() const { return (sampleType & monoSample) == monoSample; }
    bool isRight() const { return (sampleType & rightSample) == rightSample; }
    bool isLeft() const { return (sampleType & leftSample) == leftSample; }
    bool isROM() const { return (sampleType & rom) == rom; }

    void dump(const std::string& indent, int index) const;

    size_t begin() const { return dwStart; }
    size_t end() const { return dwEnd; }
    size_t loopBegin() const { return dwStartLoop; }
    size_t loopEnd() const { return dwEndLoop; }
    size_t sampleRate() const { return dwSampleRate; }

    Int originalMIDIKey() const { return originalKey; }
    Int pitchCorrection() const { return correction; }

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

inline std::string SampleHeader::sampleTypeDescription() const
{
    std::string tag("");
    if (sampleType & monoSample) tag += "M";
    if (sampleType & rightSample) tag += "R";
    if (sampleType & leftSample) tag += "L";
    if (sampleType & rom) tag += "*";
    return tag;
}

inline void SampleHeader::dump(const std::string& indent, int index) const
{
    std::cout << indent << index << ": '" << achSampleName
    << "' sampleRate: " << dwSampleRate
    << " s: " << dwStart << " e: " << dwEnd << " link: " << sampleLink
    << " type: " << sampleType << ' ' << sampleTypeDescription()
    << " originalKey: " << int(originalKey) << " correction: " << int(correction)
    << std::endl;
}

}
}
