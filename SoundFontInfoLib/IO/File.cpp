// Copyright © 2020 Brad Howes. All rights reserved.


#include "../Entity/Instrument.hpp"
#include "../Entity/Preset.hpp"

#include "ChunkList.hpp"
#include "File.hpp"

using namespace SF2::IO;

File::File(int fd, size_t fileSize) : fd_{fd}, size_{fileSize}, sampleDataBegin_{0}, sampleDataEnd_{0}
{

    auto riff = Pos(fd, 0, fileSize).makeChunkList();
    if (riff.tag() != Tags::riff) throw Format::error;
    if (riff.kind() != Tags::sfbk) throw Format::error;

    auto p0 = riff.begin();
    while (p0 < riff.end()) {
        auto chunkList = p0.makeChunkList();
        // std::cout << "chunkList: tag: " << chunkList.tag().toString() << " kind: " << chunkList.kind().toString() << std::endl;
        auto p1 = chunkList.begin();
        p0 = chunkList.advance();
        while (p1 < chunkList.end()) {
            auto chunk = p1.makeChunk();
            p1 = chunk.advance();
            //std::cout << "  chunk: tag: " << chunk.tag().toString() << std::endl;
            switch (chunk.tag().rawValue()) {
                case Tags::inam: embeddedName_ = chunk.extract(); break;
                case Tags::icop: embeddedCopyright_ = chunk.extract(); break;
                case Tags::ieng: embeddedAuthor_ = chunk.extract(); break;
                case Tags::icmt: embeddedComment_ = chunk.extract(); break;
                case Tags::phdr: presets_.load(chunk); break;
                case Tags::pbag: presetZones_.load(chunk); break;
                case Tags::pgen: presetZoneGenerators_.load(chunk); break;
                case Tags::pmod: presetZoneModulators_.load(chunk); break;
                case Tags::inst: instruments_.load(chunk); break;
                case Tags::ibag: instrumentZones_.load(chunk); break;
                case Tags::igen: instrumentZoneGenerators_.load(chunk); break;
                case Tags::imod: instrumentZoneModulators_.load(chunk); break;
                case Tags::shdr: samples_.load(chunk); break;
                case Tags::smpl:
                    sampleDataBegin_ = chunk.begin().offset();
                    sampleDataEnd_ = chunk.end().offset();
                    break;
            }
        }
    }
}
