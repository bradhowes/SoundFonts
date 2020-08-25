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
    ChunkItems<SFPreset> presets;
    ChunkItems<SFBag> presetZones;
    ChunkItems<SFGenerator> presetZoneGenerators;
    ChunkItems<SFModulator> presetZoneModulators;

    ChunkItems<SFInstrument> instruments;
    ChunkItems<SFBag> instrumentZones;
    ChunkItems<SFGenerator> instrumentZoneGenerators;
    ChunkItems<SFModulator> instrumentZoneModulators;

    ChunkItems<SFSample> samples;

    uint8_t const* sampleData;
    uint8_t const* sampleDataEnd;

    /**
     Use the given RIFF chunk to locate specific SF2 components.
     */
    explicit SFFile(Chunk const& chunk) {
        buildWith(chunk);
        validate();
    }

private:

    void buildWith(Chunk const& chunk);
    void validate();
};

}
