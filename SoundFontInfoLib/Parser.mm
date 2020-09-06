// Copyright © 2020 Brad Howes. All rights reserved.

#include <string>

#include "Chunk.hpp"
#include "Format.hpp"
#include "Parser.hpp"
#include "StringUtils.hpp"
#include "SFPreset.hpp"

using namespace SF2;

Parser::Info
Parser::parse(int fd, size_t size)
{
    Parser::Info info;

    auto riff = Pos(fd, 0).makeChunkList();
    if (riff.tag() != Tags::riff) throw Format::error;
    if (riff.kind() != Tags::sfbk) throw Format::error;

    auto p0 = riff.begin();
    while (p0 < riff.end()) {
        auto chunks = p0.makeChunkList();
        auto p1 = chunks.begin();
        while (p1 < chunks.end()) {
            auto chunk = p1.makeChunk();
            if (chunk.tag() == Tags::inam) {
                char name[256];
                chunk.dataPos().readInto(name, chunk.dataSize());
                trim_property(name);
                info.embeddedName = std::string(name);
            }
            else if (chunk.tag() == Tags::phdr) {
                auto p2 = chunk.dataPos();
                while (p2 < chunk.dataEnd()) {
                    SFPreset sfp(p2);
                    info.presets.emplace_back(sfp.name(), sfp.bank(), sfp.preset());
                    p2 = p2.advance(SFPreset::size);
                }

                info.presets.pop_back();
                return info;
            }
            p1 = chunk.next();
        }
        p0 = chunks.next();
    }

    throw Format::error;
}
