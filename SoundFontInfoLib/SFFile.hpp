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
struct SFFile {
    /// Collection of presets defined in the file
    ChunkItems<SFPreset> presets;
    /// Collection of preset zones defined in the file
    ChunkItems<SFBag> presetZones;
    /// Collection of generators (settings) for the zones
    ChunkItems<SFGenerator> presetZoneGenerators;
    /// Collection of modulator mappings for the zones
    ChunkItems<SFModulator> presetZoneModulators;

    /// Collection of instruments defined in the file. An instrument is made up of one or more zones.
    ChunkItems<SFInstrument> instruments;
    /// Collection of zones defined in the file. A zone is defined by a key range and/or a velocity range. There can be more than one zone for an instrument.
    ChunkItems<SFBag> instrumentZones;
    /// Collection of generators (settings) for the zones
    ChunkItems<SFGenerator> instrumentZoneGenerators;
    /// Collection of modulator mappings for the zones
    ChunkItems<SFModulator> instrumentZoneModulators;

    /// Collection of sample definitions used by the instruments. Defines the samples that are used to render a sound, including places where a sample can loop to
    /// generate an infinite output.
    ChunkItems<SFSample> samples;

    /// Pointer to the first sample byte from the file
    uint8_t const* sampleData;
    /// Pointer to the last+1 sample byte from the file
    uint8_t const* sampleDataEnd;

    /**
     Parse the given collection of bytes from an SF2 file and build up the collections. Since the data vector is moved into the new SFFile instance, there are no lifetime
     issues to contend with.
     */
    explicit SFFile(std::vector<char>&& data) : data_{data}, top_{Parser::parse(data_.data(), data_.size())}
    {
        buildWith(top_);
    }

    /**
     Build the collections from the given Chunk. NOTE: the Chunk lifetime must outlive the SFFile instance for the contents of the collections to be valid.
     */
    explicit SFFile(Chunk&& chunk) : data_{}, top_{std::move(chunk)}
    {
        buildWith(top_);
    }

    /**
     Build the collections from the given data after parsing it. NOTE the data pointer musrt outlve the SFFle instance for the contents of the collections to be valid.
     */
    SFFile(void const* data, size_t size) : data_{}, top_{Parser::parse(data, size)}
    {
        buildWith(top_);
    }

    /**
     Load data from a file.
     */
    static SFFile Make(std::string const& path) {
        std::ifstream file(path, std::ios::binary | std::ios::ate);
        std::streamsize size = file.tellg();
        file.seekg(0, std::ios::beg);
        std::vector<char> data(size);
        if (!file.read(data.data(), size)) throw Format::error;
        return SFFile(std::move(data));
    }

    void dump() const { top_.dump(""); }

private:

    void buildWith(Chunk const& chunk);
    void validate();

    std::vector<char> data_;
    Chunk top_;
};

}
