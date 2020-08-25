// Copyright © 2020 Brad Howes. All rights reserved.

#include "Patch.hpp"
#include "SFFile.hpp"

using namespace SF2;

Patch::Patch(SFFile const& file, uint16_t presetIndex)
: configuration_{file.presets[presetIndex]}, zones_{}
{
}
