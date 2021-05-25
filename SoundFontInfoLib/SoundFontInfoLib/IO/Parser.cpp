// Copyright © 2020 Brad Howes. All rights reserved.

#include <string>

#include "Entity/Preset.hpp"

#include "IO/ChunkList.hpp"
#include "IO/Format.hpp"
#include "IO/Parser.hpp"
#include "IO/StringUtils.hpp"

using namespace SF2::IO;

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
        auto p1 = chunkList.begin();
        p0 = chunkList.advance();
        while (p1 < chunkList.end()) {
            auto chunk = p1.makeChunk();
            p1 = chunk.advance();
            switch (chunk.tag().rawValue()) {
                case Tags::inam:
                    info.embeddedName = chunk.extract();
                    break;
                case Tags::icop:
                    info.embeddedCopyright = chunk.extract();
                    break;

                case Tags::ieng:
                    info.embeddedAuthor = chunk.extract();
                    break;

                case Tags::icmt:
                    info.embeddedComment = chunk.extract();
                    break;
                    
                case Tags::phdr:
                    auto p2 = chunk.begin();
                    while (p2 < chunk.end()) {
                        Entity::Preset sfp(p2);
                        info.presets.emplace_back(sfp.name(), sfp.bank(), sfp.preset());
                    }
                    info.presets.pop_back();
                    break;
            }
        }
    }

    if (info.presets.empty()) throw Format::error;
    return info;
}
