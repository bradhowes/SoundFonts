// Copyright © 2020 Brad Howes. All rights reserved.


#include "Entity/Instrument.hpp"
#include "Entity/Preset.hpp"
#include "IO/ChunkList.hpp"
#include "IO/File.hpp"

using namespace SF2::IO;

File::File(int fd, size_t fileSize)
: fd_{fd}, size_{fileSize}, sampleDataBegin_{0}, sampleDataEnd_{0}, sampleData_{nullptr}
{
    sampleData_ = nullptr;

    auto riff = Pos(fd, 0, fileSize).makeChunkList();
    if (riff.tag() != Tags::riff) throw Format::error;
    if (riff.kind() != Tags::sfbk) throw Format::error;

    auto p0 = riff.begin();
    while (p0 < riff.end()) {
        auto chunkList = p0.makeChunkList();
        std::cout << "chunkList: tag: " << chunkList.tag().toString() << " kind: " << chunkList.kind().toString() << std::endl;
        auto p1 = chunkList.begin();
        p0 = chunkList.advance();
        while (p1 < chunkList.end()) {
            auto chunk = p1.makeChunk();
            p1 = chunk.advance();
            std::cout << "  chunk: tag: " << chunk.tag().toString() << std::endl;
            switch (chunk.tag().rawValue()) {

                // Meta data chunks
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

                // Preset-related chunks
                case Tags::phdr: presets_.load(chunk); break;
                case Tags::pbag: presetZones_.load(chunk); break;
                case Tags::pgen: presetZoneGenerators_.load(chunk); break;
                case Tags::pmod: presetZoneModulators_.load(chunk); break;

                // Instrument-related chunks
                case Tags::inst: instruments_.load(chunk); break;
                case Tags::ibag: instrumentZones_.load(chunk); break;
                case Tags::igen: instrumentZoneGenerators_.load(chunk); break;
                case Tags::imod: instrumentZoneModulators_.load(chunk); break;

                // Audio sample chunks
                case Tags::shdr:
                    sampleHeaders_.load(chunk);
                    sampleHeaders_.dump("shdr: ");
                    break;
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
        sampleBuffers_.emplace_back(sampleData_, header);
    }
}

void
File::dump() const {
    instruments().dump("inst: ");
    instrumentZones().dump("instZones: ");
    instrumentZoneGenerators().dump("igen: ");
    instrumentZoneModulators().dump("imod: ");

    presets().dump("presets: ");
    presetZones().dump("presetZones: ");
    presetZoneGenerators().dump("pgen: ");
    presetZoneModulators().dump("pmod: ");
}
