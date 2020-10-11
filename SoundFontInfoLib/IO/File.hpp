// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <fstream>

#include "../Entity/Bag.hpp"
#include "../Entity/Generator.hpp"
#include "../Entity/Instrument.hpp"
#include "../Entity/Modulator.hpp"
#include "../Entity/Preset.hpp"
#include "../Entity/Sample.hpp"

#include "ChunkItems.hpp"

namespace SF2 {
namespace IO {

/**
 Contains collection of SF2 elements found in a SF2 file.
 */
class File {
public:
    explicit File(int fd, size_t size);

    std::string const& embeddedName() const { return embeddedName_; }
    ::SF2::IO::ChunkItems<::SF2::Entity::Preset> const& presets() const { return presets_; };
    ::SF2::IO::ChunkItems<::SF2::Entity::Bag> const& presetZones() const { return presetZones_; };
    ::SF2::IO::ChunkItems<::SF2::Entity::Generator> const& presetZoneGenerators() const { return presetZoneGenerators_; };
    ::SF2::IO::ChunkItems<::SF2::Entity::Modulator> const& presetZoneModulators() const { return presetZoneModulators_; };
    ::SF2::IO::ChunkItems<::SF2::Entity::Instrument> const& instruments() const { return instruments_; };
    ::SF2::IO::ChunkItems<::SF2::Entity::Bag> const& instrumentZones() const { return instrumentZones_; };
    ::SF2::IO::ChunkItems<::SF2::Entity::Generator> const& instrumentZoneGenerators() const { return instrumentZoneGenerators_; };
    ::SF2::IO::ChunkItems<::SF2::Entity::Modulator> const& instrumentZoneModulators() const { return instrumentZoneModulators_; };
    ::SF2::IO::ChunkItems<::SF2::Entity::Sample> const& samples() const { return samples_; };

private:
    int fd_;
    size_t size_;
    size_t sampleDataBegin_;
    size_t sampleDataEnd_;
    std::string embeddedName_;
    ::SF2::IO::ChunkItems<::SF2::Entity::Preset> presets_;
    ::SF2::IO::ChunkItems<::SF2::Entity::Bag> presetZones_;
    ::SF2::IO::ChunkItems<::SF2::Entity::Generator> presetZoneGenerators_;
    ::SF2::IO::ChunkItems<::SF2::Entity::Modulator> presetZoneModulators_;
    ::SF2::IO::ChunkItems<::SF2::Entity::Instrument> instruments_;
    ::SF2::IO::ChunkItems<::SF2::Entity::Bag> instrumentZones_;
    ::SF2::IO::ChunkItems<::SF2::Entity::Generator> instrumentZoneGenerators_;
    ::SF2::IO::ChunkItems<::SF2::Entity::Modulator> instrumentZoneModulators_;
    ::SF2::IO::ChunkItems<::SF2::Entity::Sample> samples_;
};

}
}
