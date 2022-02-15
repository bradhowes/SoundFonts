// Copyright © 2020 Brad Howes. All rights reserved.

#include <iostream>
#include <map>

#include "Entity/Instrument.hpp"
#include "Entity/Preset.hpp"
#include "IO/ChunkList.hpp"
#include "IO/File.hpp"

using namespace SF2::IO;

File::File(int fd, size_t fileSize, bool dump)
: fd_{fd}, size_{fileSize}, sampleDataBegin_{0}, sampleDataEnd_{0}, sampleData_{nullptr}
{
  sampleData_ = nullptr;

  auto riff = Pos(fd, 0, fileSize).makeChunkList();
  if (riff.tag() != Tags::riff) throw Format::error;
  if (riff.kind() != Tags::sfbk) throw Format::error;

  auto p0 = riff.begin();
  while (p0 < riff.end()) {
    auto chunkList = p0.makeChunkList();

    if (dump) {
      log_.debug() << "chunkList: tag: " << chunkList.tag().toString() << " kind: " << chunkList.kind().toString()
      << std::endl;
    }

    auto p1 = chunkList.begin();
    p0 = chunkList.advance();
    while (p1 < chunkList.end()) {
      auto chunk = p1.makeChunk();
      p1 = chunk.advance();
      if (dump) {
        log_.debug() << "chunk: tag: " << chunk.tag().toString() << std::endl;
      }
      switch (chunk.tag().rawValue()) {
        case Tags::ifil: soundFontVersion_.load(chunk.begin()); break;
        case Tags::isng: soundEngine_ = chunk.extract(); break;
        case Tags::irom: rom_ = chunk.extract(); break;
        case Tags::iver: fileVersion_.load(chunk.begin()); break;
        case Tags::inam: embeddedName_ = chunk.extract(); break;
        case Tags::icrd: embeddedCreationDate_ = chunk.extract(); break;
        case Tags::ieng: embeddedAuthor_ = chunk.extract(); break;
        case Tags::iprd: embeddedProduct_ = chunk.extract(); break;
        case Tags::icop: embeddedCopyright_ = chunk.extract(); break;
        case Tags::icmt: embeddedComment_ = chunk.extract(); break;
        case Tags::istf: embeddedTools_ = chunk.extract(); break;
        case Tags::phdr: presets_.load(chunk); break;
        case Tags::pbag: presetZones_.load(chunk); break;
        case Tags::pgen: presetZoneGenerators_.load(chunk); break;
        case Tags::pmod: presetZoneModulators_.load(chunk); break;
        case Tags::inst: instruments_.load(chunk); break;
        case Tags::ibag: instrumentZones_.load(chunk); break;
        case Tags::igen: instrumentZoneGenerators_.load(chunk); break;
        case Tags::imod: instrumentZoneModulators_.load(chunk); break;
        case Tags::shdr: sampleHeaders_.load(chunk); break;
        case Tags::smpl:
          sampleDataBegin_ = chunk.begin().offset();
          sampleDataEnd_ = chunk.end().offset();
          sampleData_ = chunk.extractSamples();
          break;
      }
    }
  }

  assert(sampleData_ != nullptr);
  sampleBuffers_.reserve(sampleHeaders_.size());
  for (auto index = 0; index < sampleHeaders_.size(); ++index) {
    auto const& header = sampleHeaders_[index];
    sampleBuffers_.emplace_back(sampleData_.get(), header);
  }
}

void
File::patchReleaseTimes(float maxDuration) {
  int limit = int(log2(maxDuration) * 1200.0 + 0.5);
  std::cout << "maxDuration: " << maxDuration << " limit: " << limit << '\n';

  std::map<int, int> visited;
  for (auto phdrIndex = 0; phdrIndex < presets_.size(); ++phdrIndex) {
    const auto& preset{presets_[phdrIndex]};
    for (auto pbagIndex = 0; pbagIndex < preset.zoneCount(); ++pbagIndex) {
      const auto& pbag{presetZones_[pbagIndex + preset.firstZoneIndex()]};
      for (auto pgenIndex = 0; pgenIndex < pbag.generatorCount(); ++pgenIndex) {
        const auto& pgen{presetZoneGenerators_[pgenIndex + pbag.firstGeneratorIndex()]};
        if (pgen.index() == Entity::Generator::Index::instrument) {
          auto instrumentIndex = pgen.amount().unsignedAmount();
          const auto& inst{instruments_[instrumentIndex]};
          auto found = visited.find(instrumentIndex);
          if (found != visited.end()) {
            continue;
          }
          visited.insert(std::pair(instrumentIndex, 1));
          for (auto ibagIndex = 0; ibagIndex < inst.zoneCount(); ++ibagIndex) {
            const auto& ibag{instrumentZones_[ibagIndex + inst.firstZoneIndex()]};
            for (auto igenIndex = 0; igenIndex < ibag.generatorCount(); ++igenIndex) {
              const auto& igen{instrumentZoneGenerators_[igenIndex + ibag.firstGeneratorIndex()]};
              if (igen.index() == Entity::Generator::Index::releaseVolumeEnvelope) {
                if (igen.value() > limit) {
                  preset.dump("phdr", phdrIndex);
                  inst.dump(" inst", instrumentIndex);
                  igen.dump("  igen", igenIndex + ibag.firstGeneratorIndex());
                }
              }
            }
          }
        }
      }
    }
  }
}

void
File::dump() const {
  std::cout << "|-phdr"; presets().dump("|-phdr: ");
  std::cout << "|-pbag"; presetZones().dump("|-pbag: ");
  std::cout << "|-pgen"; presetZoneGenerators().dump("|-pgen: ");
  std::cout << "|-pmod"; presetZoneModulators().dump("|-pmod: ");
  std::cout << "|-inst"; instruments().dump("|-inst: ");
  std::cout << "|-ibag"; instrumentZones().dump("|-ibag: ");
  std::cout << "|-igen"; instrumentZoneGenerators().dump("|-igen: ");
  std::cout << "|-imod"; instrumentZoneModulators().dump("|-imod: ");
  std::cout << "|-shdr"; sampleHeaders().dump("|-shdr: ");
}

void
File::dumpThreaded() const {
  std::map<int, int> instrumentLines;
  int lineCounter = 1;
  for (auto phdrIndex = 0; phdrIndex < presets_.size(); ++phdrIndex) {
    const auto& preset{presets_[phdrIndex]};

    // Dump preset header
    preset.dump("phdr", phdrIndex); ++lineCounter;
    for (auto pbagIndex = 0; pbagIndex < preset.zoneCount(); ++pbagIndex) {

      // Dump preset zone. If the zone's generator set is empty or does not end with a link to an instrument, it
      // is global.
      const auto& pbag{presetZones_[pbagIndex + preset.firstZoneIndex()]};
      if (pbag.generatorCount() == 0 ||
          presetZoneGenerators_[pbag.firstGeneratorIndex() + pbag.generatorCount() - 1].index() !=
          Entity::Generator::Index::instrument) {
        pbag.dump(" PBAG", pbagIndex + preset.firstZoneIndex()); ++lineCounter;
      }
      else {
        pbag.dump(" pbag", pbagIndex + preset.firstZoneIndex()); ++lineCounter;
      }

      // Dump the modulators for the zone. Per spec, this should be empty
      for (auto pmodIndex = 0; pmodIndex < pbag.modulatorCount(); ++pmodIndex) {
        const auto& pmod{presetZoneModulators_[pmodIndex + pbag.firstModulatorIndex()]};
        pmod.dump("  pmod", pmodIndex + pbag.firstModulatorIndex()); ++lineCounter;
      }

      // Dump the generators for the zone.
      for (auto pgenIndex = 0; pgenIndex < pbag.generatorCount(); ++pgenIndex) {
        const auto& pgen{presetZoneGenerators_[pgenIndex + pbag.firstGeneratorIndex()]};
        pgen.dump("  pgen", pgenIndex + pbag.firstGeneratorIndex()); ++lineCounter;

        // If the (last) generator is for an instrument, dump out the instrument.
        if (pgen.index() == Entity::Generator::Index::instrument) {
          auto instrumentIndex = pgen.amount().unsignedAmount();
          const auto& inst{instruments_[instrumentIndex]};
          inst.dump("   inst", instrumentIndex); ++lineCounter;

          // See if we have already dumped out the contents of the instrument's zones
          auto found = instrumentLines.find(instrumentIndex);
          if (found != instrumentLines.end()) {
            std::cout << "   inst *** see line " << found->second << std::endl; ++lineCounter;
            continue;
          }

          instrumentLines.insert(std::pair(instrumentIndex, lineCounter - 1));
          for (auto ibagIndex = 0; ibagIndex < inst.zoneCount(); ++ibagIndex) {

            // Dump instrument zone. If the zone's generator set is empty or does not end with a link to a
            // sample header, it is global.
            const auto& ibag{instrumentZones_[ibagIndex + inst.firstZoneIndex()]};
            if (ibag.generatorCount() == 0 ||
                instrumentZoneGenerators_[ibag.firstGeneratorIndex() + ibag.generatorCount() - 1].index() !=
                Entity::Generator::Index::sampleID) {
              ibag.dump("    IBAG", ibagIndex + inst.firstZoneIndex()); ++lineCounter;
            }
            else {
              ibag.dump("    ibag", ibagIndex + inst.firstZoneIndex()); ++lineCounter;
            }

            // Dump the modulator definitions for the zone
            for (auto imodIndex = 0; imodIndex < ibag.modulatorCount(); ++imodIndex) {
              const auto& imod{instrumentZoneModulators_[imodIndex + ibag.firstModulatorIndex()]};
              imod.dump("     imod", imodIndex + ibag.firstModulatorIndex()); ++lineCounter;
            }

            // Dump the generators for the zone
            for (auto igenIndex = 0; igenIndex < ibag.generatorCount(); ++igenIndex) {
              const auto& igen{instrumentZoneGenerators_[igenIndex + ibag.firstGeneratorIndex()]};
              igen.dump("     igen", igenIndex + ibag.firstGeneratorIndex()); ++lineCounter;

              // If the (last) generator is for a sample, dump the sample header.
              if (igen.index() == Entity::Generator::Index::sampleID) {
                auto sampleIndex = igen.amount().unsignedAmount();
                const auto& shdr{sampleHeaders_[sampleIndex]};
                shdr.dump("      shdr", sampleIndex); ++lineCounter;
              }
            }
          }
        }
      }
    }
  }
}
