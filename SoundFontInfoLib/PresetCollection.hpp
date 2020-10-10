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
    PresetCollection(SFFile const& file, InstrumentCollection const& instruments);

    Preset const& at(size_t index) const { return presets_.at(index); }

private:
    std::vector<Preset> presets_;
};

}
