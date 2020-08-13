// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "Instruments.hpp"
#include "InstrumentZones.hpp"
#include "InstrumentZoneGens.hpp"
#include "InstrumentZoneMods.hpp"
#include "Presets.hpp"
#include "PresetZones.hpp"
#include "PresetZoneGens.hpp"
#include "PresetZoneMods.hpp"
#include "Samples.hpp"

namespace SF2 {

struct SFFile {
    Presets presets;
    PresetZones presetZones;
    PresetZoneGens presetZoneGens;
    PresetZoneMods presetZoneMods;

    Instruments instruments;
    InstrumentZones instrumentZones;
    InstrumentZoneGens instrumentZoneGens;
    InstrumentZoneMods instrumentZoneMods;

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
            }
        }
        else {
            std::for_each(chunk.begin(), chunk.end(), [this](Chunk const& chunk) { buildWith(chunk); });
        }
    }
};

}
