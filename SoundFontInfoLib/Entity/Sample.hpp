// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <iostream>

#include "../IO/Pos.hpp"
#include "../IO/StringUtils.hpp"

namespace SF2 {
namespace Entity {

/**
 Define the audio samples to be used for playing a specific sound.

 Memory layout of a 'shdr' entry. The size of this is defined to be 46 bytes, but due
 to alignment/padding the struct below is 48 bytes.
 */
class Sample {
public:
    constexpr static size_t size = 46;

    explicit Sample(IO::Pos& pos)
    {
        assert(sizeof(*this) == size + 2);
        // Account for the extra padding by reading twice.
        pos = pos.readInto(&achSampleName, 40);
        pos = pos.readInto(&originalKey, 6);
        IO::trim_property(achSampleName);
    }

    enum Type {
        monoSample = 1,
        rightSample = 2,
        leftSample = 4,
        linkedSample = 8,
        rom = 0x8000
    };

    bool isMono() const { return (sampleType & monoSample) == monoSample; }
    bool isRight() const { return (sampleType & rightSample) == rightSample; }
    bool isLeft() const { return (sampleType & leftSample) == leftSample; }
    bool isROM() const { return (sampleType & rom) == rom; }

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

inline std::string Sample::sampleTypeDescription() const
{
    std::string tag("");
    if (sampleType & monoSample) tag += "M";
    if (sampleType & rightSample) tag += "R";
    if (sampleType & leftSample) tag += "L";
    if (sampleType & rom) tag += "*";
    return tag;
}

inline void Sample::dump(const std::string& indent, int index) const
{
    std::cout << indent << index << ": '" << achSampleName
    << "' sampleRate: " << dwSampleRate
    << " s: " << dwStart << " e: " << dwEnd << " link: " << sampleLink
    << " type: " << sampleType << ' ' << sampleTypeDescription()
    << std::endl;
}

}
}
