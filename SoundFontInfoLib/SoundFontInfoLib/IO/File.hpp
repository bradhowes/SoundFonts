// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <fstream>
#include <memory>
#include <vector>

#include "Logger.hpp"

#include "Entity/Bag.hpp"
#include "Entity/Generator/Generator.hpp"
#include "Entity/Instrument.hpp"
#include "Entity/Modulator/Modulator.hpp"
#include "Entity/Preset.hpp"
#include "Entity/SampleHeader.hpp"
#include "Entity/Version.hpp"

#include "IO/ChunkItems.hpp"
#include "Render/NormalizedSampleSource.hpp"

/**
 Collection of classes and types involved in parsing an SF2 file or data stream.
 */
namespace SF2::IO {

/**
 Represents an SF2 file. The constructor will process the entire file to validate its integrity and record the
 locations of the nine entities that define an SF2 file. It also extracts certain meta data items from various chunks
 such as the embedded name, author, and copyright statement.
 */
class File {
public:

  File() = default;

  /**
   Constructor. Processes the SF2 file contents and builds up various collections based on what it finds.

   @param fd the file descriptor to read from
   @param dump if true, dump contents of file to log stream
   */
  File(int fd, bool dump = false);

  enum class LoadResponse {
    ok,
    notFound,
    invalidFormat
  };

  LoadResponse load(int fd, bool dump = false);

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
  const ChunkItems<Entity::SampleHeader>& sampleHeaders() const { return sampleHeaders_; };

  /**
   Obtain a SampleBuffer at the given sample header index

   @param index the index of the buffer to obtain
   @returns SampleBuffer reference
   */
  const Render::NormalizedSampleSource& sampleSource(uint16_t index) const { return sampleSources_[index]; }

  void patchReleaseTimes(float maxDuration);
  
  void dumpThreaded() const;

  void dump() const;

private:
  off_t size_;
  off_t sampleDataBegin_;
  off_t sampleDataEnd_;
  Entity::Version soundFontVersion_;
  Entity::Version fileVersion_;

  std::string soundEngine_;
  std::string rom_;
  std::string embeddedName_;
  std::string embeddedCreationDate_;
  std::string embeddedAuthor_;
  std::string embeddedProduct_;
  std::string embeddedCopyright_;
  std::string embeddedComment_;
  std::string embeddedTools_;

  ChunkItems<Entity::Preset> presets_;
  ChunkItems<Entity::Bag> presetZones_;
  ChunkItems<Entity::Generator::Generator> presetZoneGenerators_;
  ChunkItems<Entity::Modulator::Modulator> presetZoneModulators_;
  ChunkItems<Entity::Instrument> instruments_;
  ChunkItems<Entity::Bag> instrumentZones_;
  ChunkItems<Entity::Generator::Generator> instrumentZoneGenerators_;
  ChunkItems<Entity::Modulator::Modulator> instrumentZoneModulators_;
  ChunkItems<Entity::SampleHeader> sampleHeaders_;

  std::vector<Render::NormalizedSampleSource> sampleSources_;

  std::shared_ptr<int16_t> sampleData_;

  inline static Logger log_{Logger::Make("IO", "File")};
};

} // end namespace SF2::IO
