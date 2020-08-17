// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "Instruments.hpp"
#include "Presets.hpp"
#include "Samples.hpp"
#include "Zones.hpp"
#include "ZoneGens.hpp"
#include "ZoneMods.hpp"

namespace SF2 {

struct SFFile {
    Presets presets;
    Zones presetZones;
    ZoneGens presetZoneGens;
    ZoneMods presetZoneMods;

    Instruments instruments;
    Zones instrumentZones;
    ZoneGens instrumentZoneGens;
    ZoneMods instrumentZoneMods;

    Samples samples;

    SFFile(Chunk const& chunk) { buildWith(chunk); }

private:
    void buildWith(Chunk const& chunk) {
        if (chunk.dataPtr() != nullptr) {
            switch (chunk.tag().toInt()) {
                case Tags::phdr: presets.load(chunk); break;
                case Tags::pbag: presetZones.load(chunk); break;
                case Tags::pgen: presetZoneGens.load(chunk); break;
                case Tags::pmod: presetZoneMods.load(chunk); break;
                case Tags::inst: instruments.load(chunk); break;
                case Tags::ibag: instrumentZones.load(chunk); break;
                case Tags::igen: instrumentZoneGens.load(chunk); break;
                case Tags::imod: instrumentZoneMods.load(chunk); break;
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
