// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <fstream>

#include "Entity/Bag.hpp"
#include "Entity/Generator/Generator.hpp"
#include "Entity/Instrument.hpp"
#include "Entity/Modulator/Modulator.hpp"
#include "Entity/Preset.hpp"
#include "Entity/Sample.hpp"

#include "IO/ChunkItems.hpp"

namespace SF2 {
namespace IO {

/**
 Represents an SF2 file. The constructor will process the entire file to validate its integrity and record the
 locations of the nine entities that define an SF2 file. It also extracts certain meta data items from various chunks
 such as the embedded name, author, and copyright statement.
 */
class File {
public:

    /**
     Constructor. Processes the SF2 file contents and builds up various collections based on what it finds

     @param fd the file descriptor to read from
     @param size the size of the file being processed
     */
    File(int fd, size_t size);

    /// @returns the embedded name in the file
    const std::string& embeddedName() const { return embeddedName_; }

    /// @returns the embedded author name in the file
    const std::string& embeddedAuthor() const { return embeddedAuthor_; }

    /// @returns any embedded comment in the file
    const std::string& embeddedComment() const { return embeddedComment_; }

    /// @returns any embedded copyright notice in the file
    const std::string& embeddedCopyright() const { return embeddedCopyright_; }

    /// @returns reference to preset definitions found in the file
    const ChunkItems<Entity::Preset>& presets() const { return presets_; };

    /// @returns reference to preset zone definitions
    const ChunkItems<Entity::Bag>& presetZones() const { return presetZones_; };

    /// @returns reference to preset zone generator definitions
    const ChunkItems<Entity::Generator::Generator>& presetZoneGenerators() const { return presetZoneGenerators_; };

    /// @returns reference to preset zone modulator definitions
    const ChunkItems<Entity::Modulator::Modulator>& presetZoneModulators() const { return presetZoneModulators_; };

    /// @returns reference to instrument definitions found in the file
    const ChunkItems<Entity::Instrument>& instruments() const { return instruments_; };

    /// @returns reference to instrument zone definitions
    const ChunkItems<Entity::Bag>& instrumentZones() const { return instrumentZones_; };

    /// @returns reference to instrument zone generator definitions
    const ChunkItems<Entity::Generator::Generator>& instrumentZoneGenerators() const { return instrumentZoneGenerators_; };

    /// @returns reference to instrument zone modulator definitions
    const ChunkItems<Entity::Modulator::Modulator>& instrumentZoneModulators() const { return instrumentZoneModulators_; };

    /// @returns reference to samples definitions
    const ChunkItems<Entity::Sample>& samples() const { return samples_; };

private:
    int fd_;
    size_t size_;
    size_t sampleDataBegin_;
    size_t sampleDataEnd_;
    std::string embeddedName_;
    std::string embeddedAuthor_;
    std::string embeddedComment_;
    std::string embeddedCopyright_;

    ChunkItems<Entity::Preset> presets_;
    ChunkItems<Entity::Bag> presetZones_;
    ChunkItems<Entity::Generator::Generator> presetZoneGenerators_;
    ChunkItems<Entity::Modulator::Modulator> presetZoneModulators_;
    ChunkItems<Entity::Instrument> instruments_;
    ChunkItems<Entity::Bag> instrumentZones_;
    ChunkItems<Entity::Generator::Generator> instrumentZoneGenerators_;
    ChunkItems<Entity::Modulator::Modulator> instrumentZoneModulators_;
    ChunkItems<Entity::Sample> samples_;
};

}
}
