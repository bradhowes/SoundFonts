// Copyright © 2020 Brad Howes. All rights reserved.

#include "Sample.hpp"
#include "StringUtils.hpp"

using namespace SF2;

void
sfSample::dump(const std::string& indent, int index) const
{
    std::cout << indent << index << ": '" << achSampleName
    << "' sampleRate: " << dwSampleRate
    << " s: " << dwStart << " e: " << dwEnd << " link: " << sampleLink
    << " type: " << sampleType
    << std::endl;
}

const char*
sfSample::load(const char* pos, size_t available)
{
    if (available < 46) throw FormatError;
    memcpy(&achSampleName, pos, 40);
    pos += 40;
    memcpy(&originalIPitch, pos, 6);
    pos += 6;
    std::string name(achSampleName, 19);
    trim(name);
    strncpy(achSampleName, name.c_str(), name.size() + 1);
    return pos;
}
