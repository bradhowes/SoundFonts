// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <fstream>

#include "ChunkItems.hpp"
#include "Parser.hpp"
#include "SFBag.hpp"
#include "SFGenerator.hpp"
#include "SFInstrument.hpp"
#include "SFModulator.hpp"
#include "SFPreset.hpp"
#include "SFSample.hpp"

namespace SF2 {

/**
 Contains collection of SF2 elements found in a SF2 file.
 */
class SFFile {
public:
    explicit SFFile(int fd, size_t size);

    std::string const& embeddedName() const { return embeddedName_; }
    ChunkItems<SFPreset> const& presets() const { return presets_; };
    ChunkItems<SFBag> const& presetZones() const { return presetZones_; };
    ChunkItems<SFGenerator> const& presetZoneGenerators() const { return presetZoneGenerators_; };
    ChunkItems<SFModulator> const& presetZoneModulators() const { return presetZoneModulators_; };
    ChunkItems<SFInstrument> const& instruments() const { return instruments_; };
    ChunkItems<SFBag> const& instrumentZones() const { return instrumentZones_; };
    ChunkItems<SFGenerator> const& instrumentZoneGenerators() const { return instrumentZoneGenerators_; };
    ChunkItems<SFModulator> const& instrumentZoneModulators() const { return instrumentZoneModulators_; };
    ChunkItems<SFSample> const& samples() const { return samples_; };

private:
    int fd_;
    size_t size_;
    size_t sampleDataBegin_;
    size_t sampleDataEnd_;
    std::string embeddedName_;
    ChunkItems<SFPreset> presets_;
    ChunkItems<SFBag> presetZones_;
    ChunkItems<SFGenerator> presetZoneGenerators_;
    ChunkItems<SFModulator> presetZoneModulators_;
    ChunkItems<SFInstrument> instruments_;
    ChunkItems<SFBag> instrumentZones_;
    ChunkItems<SFGenerator> instrumentZoneGenerators_;
    ChunkItems<SFModulator> instrumentZoneModulators_;
    ChunkItems<SFSample> samples_;
};

}
