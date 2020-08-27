// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "StringUtils.hpp"

namespace SF2 {

/**
 Define the audio samples to be used for playing a specific sound.

 Memory layout of a 'shdr' entry. The size of this is defined to be 46 bytes, but due
 to alignment/padding the struct below is 48 bytes.
 */
class SFSample {
public:
    constexpr static size_t size = 46;

    explicit SFSample(BinaryStream& is)
    {
        // Account for the extra padding by reading twice.
        is.copyInto(&achSampleName, 40);
        is.copyInto(&originalKey, 6);
        trim_property(achSampleName);
    }

    enum LinkType {
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

    std::string sampleTypeDescription() const
    {
        std::string tag("");
        if (sampleType & monoSample) tag += "M";
        if (sampleType & rightSample) tag += "R";
        if (sampleType & leftSample) tag += "L";
        if (sampleType & rom) tag += "*";
        return tag;
    }

    void dump(const std::string& indent, int index) const
    {
        std::cout << indent << index << ": '" << achSampleName
        << "' sampleRate: " << dwSampleRate
        << " s: " << dwStart << " e: " << dwEnd << " link: " << sampleLink
        << " type: " << sampleType << ' ' << sampleTypeDescription()
        << std::endl;
    }

private:
    char achSampleName[20];
    uint32_t dwStart;
    uint32_t dwEnd;
    uint32_t dwStartLoop;
    uint32_t dwEndLoop;
    uint32_t dwSampleRate;
    uint8_t originalKey;
    int8_t correction;
    uint16_t sampleLink;
    uint16_t sampleType;
};

}
