// Copyright © 2020 Brad Howes. All rights reserved.

#include <cmath>

#include "PresetCollection.hpp"

using namespace SF2;

PresetCollection::PresetCollection(SFFile const& file, InstrumentCollection const& instruments) : presets_{}
{
    // Do *not* process the last record. It is a sentinal used only for bag calculations.
    auto count = file.presets.size() - 1;
    presets_.reserve(count);
    for (SFPreset const& configuration : file.presets.slice(0, count)) {
        presets_.emplace_back(file, instruments, configuration);
    }
}
