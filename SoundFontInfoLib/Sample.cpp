// Copyright © 2020 Brad Howes. All rights reserved.

#include "Sample.hpp"
#include "StringUtils.hpp"

using namespace SF2;

enum SFSampleLink {
    monoSample = 1,
    rightSample = 2,
    leftSample = 4,
    linkedSample = 8,
    rom = 0x8000
};

static std::string typeDescription(uint16_t type)
{
    std::string tag("");
    if (type & monoSample) tag += "M";
    if (type & rightSample) tag += "R";
    if (type & leftSample) tag += "L";
    if (type & rom) tag += "*";
    return tag;
}

void
sfSample::dump(const std::string& indent, int index) const
{
    std::cout << indent << index << ": '" << achSampleName
    << "' sampleRate: " << dwSampleRate
    << " s: " << dwStart << " e: " << dwEnd << " link: " << sampleLink
    << " type: " << sampleType << ' ' << typeDescription(sampleType)
    << std::endl;
}

char const*
sfSample::load(char const* pos, size_t available)
{
    if (available < 46) throw FormatError;
    memcpy(&achSampleName, pos, 40);
    pos += 40;
    memcpy(&originalKey, pos, 6);
    pos += 6;
    std::string name(achSampleName, 19);
    trim(name);
    strncpy(achSampleName, name.c_str(), name.size() + 1);
    return pos;
}
