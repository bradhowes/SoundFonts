// Copyright © 2020 Brad Howes. All rights reserved.

#include <iostream>

#include "Entity/SampleHeader.hpp"

using namespace SF2::Entity;

std::string
SampleHeader::sampleTypeDescription() const
{
    std::string tag("");
    if (sampleType & monoSample) tag += "M";
    if (sampleType & rightSample) tag += "R";
    if (sampleType & leftSample) tag += "L";
    if (sampleType & rom) tag += "*";
    return tag;
}

void
SampleHeader::dump(const std::string& indent, int index) const
{
    std::cout << indent << '[' << index << "] '" << achSampleName
    << "' sampleRate: " << dwSampleRate
    << " S: " << dwStart << " E: " << dwEnd << " link: " << sampleLink
    << " SL: " << dwStartLoop << " EL: " << dwEndLoop
    << " type: " << sampleType << ' ' << sampleTypeDescription()
    << " originalKey: " << int(originalKey) << " correction: " << int(correction)
    << std::endl;
}

