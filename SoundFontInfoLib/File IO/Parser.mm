// Copyright © 2020 Brad Howes. All rights reserved.

#include <string>

#include "ChunkList.hpp"
#include "Format.hpp"
#include "Parser.hpp"
#include "StringUtils.hpp"
#include "SFPreset.hpp"

using namespace SF2;

Parser::Info
Parser::parse(int fd, size_t fileSize)
{
    Parser::Info info;

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
            if (chunk.tag() == Tags::inam) {
                char name[256];
                chunk.begin().readInto(name, chunk.size());
                trim_property(name);
                info.embeddedName = std::string(name);
            }
            else if (chunk.tag() == Tags::phdr) {
                auto p2 = chunk.begin();
                while (p2 < chunk.end()) {
                    SFPreset sfp(p2);
                    info.presets.emplace_back(sfp.name(), sfp.bank(), sfp.preset());
                }
                info.presets.pop_back();
            }
        }
    }

    if (info.presets.empty()) throw Format::error;
    return info;
}
