// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "Instruments.hpp"
#include "Presets.hpp"
#include "Samples.hpp"
#include "Zones.hpp"
#include "ZoneGenerators.hpp"
#include "ZoneModulators.hpp"

namespace SF2 {

struct SFFile {
    Presets presets;
    Zones presetZones;
    ZoneGenerators presetZoneGenerators;
    ZoneModulators presetZoneModulators;

    Instruments instruments;
    Zones instrumentZones;
    ZoneGenerators instrumentZoneGenerators;
    ZoneModulators instrumentZoneModulators;

    Samples samples;

    SFFile(Chunk const& chunk) { buildWith(chunk); }

private:
    void buildWith(Chunk const& chunk) {
        if (chunk.dataPtr() != nullptr) {
            switch (chunk.tag().toInt()) {
                case Tags::phdr: presets.load(chunk); break;
                case Tags::pbag: presetZones.load(chunk); break;
                case Tags::pgen: presetZoneGenerators.load(chunk); break;
                case Tags::pmod: presetZoneModulators.load(chunk); break;
                case Tags::inst: instruments.load(chunk); break;
                case Tags::ibag: instrumentZones.load(chunk); break;
                case Tags::igen: instrumentZoneGenerators.load(chunk); break;
                case Tags::imod: instrumentZoneModulators.load(chunk); break;
                case Tags::shdr: samples.load(chunk); break;
                case Tags::smpl: break;
            }
        }
        else {
            std::for_each(chunk.begin(), chunk.end(), [this](Chunk const& chunk) { buildWith(chunk); });
        }
    }
};

}
