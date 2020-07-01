// Copyright © 2020 Brad Howes. All rights reserved.

#include "Preset.hpp"
#include "StringUtils.hpp"

using namespace SF2;

void
sfPreset::dump(const std::string &indent, int index) const
{
    std::cout << indent << index << ": '" << achPresetName << "' preset: " << wPreset
    << " bank: " << wBank
    << " zone: " << wPresetBagNdx << std::endl;
}

char const*
sfPreset::load(char const* pos, size_t available)
{
    if (available < 38) throw FormatError;
    memcpy(&achPresetName, pos, 26);
    pos += 26;
    memcpy(&dwLibrary, pos, 12);
    pos += 12;
    std::string name(achPresetName, 19);
    trim(name);
    strncpy(achPresetName, name.c_str(), name.size() + 1);
    return pos;
}
