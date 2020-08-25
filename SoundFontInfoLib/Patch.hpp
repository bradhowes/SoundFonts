// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "SFFile.hpp"
#include "SFPreset.hpp"
#include "Zone.hpp"

namespace SF2 {

struct Patch {
    Patch(SFFile const& file, uint16_t presetIndex);

private:

    SFPreset const& configuration_;
    std::vector<Zone> zones_;
};

}
