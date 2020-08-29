// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <vector>

#include "InstrumentCollection.hpp"
#include "Preset.hpp"
#include "SFFile.hpp"

namespace SF2 {

class PresetCollection
{
public:
    PresetCollection(SFFile const& file, InstrumentCollection const& instruments) :
    presets_{}
    {
        // Do *not* process the last record. It is a sentinal used only for bag calculations.
        auto count = file.presets.size() - 1;
        presets_.reserve(count);
        for (SFPreset const& configuration : file.presets.slice(0, count)) {
            presets_.emplace_back(file, instruments, configuration);
        }
    }

    Preset const& at(size_t index) const { return presets_.at(index); }

private:
    std::vector<Preset> presets_;
};

}
