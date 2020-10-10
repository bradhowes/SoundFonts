// Copyright © 2020 Brad Howes. All rights reserved.

#include <iostream>
#include <unistd.h>

#include "ChunkList.hpp"
#include "Format.hpp"

using namespace SF2;

Chunk
Pos::makeChunk() const
{
    uint32_t buffer[2];
    if (::lseek(fd_, pos_, SEEK_SET) != pos_) throw Format::error;
    if (::read(fd_, buffer, sizeof(buffer)) != sizeof(buffer)) throw Format::error;
    return Chunk(Tag(buffer[0]), buffer[1], advance(sizeof(buffer)));
}

ChunkList
Pos::makeChunkList() const
{
    uint32_t buffer[3];
    if (::lseek(fd_, pos_, SEEK_SET) != pos_) throw Format::error;
    if (::read(fd_, buffer, sizeof(buffer)) != sizeof(buffer)) throw Format::error;
    return ChunkList(Tag(buffer[0]), buffer[1] - 4, Tag(buffer[2]), advance(sizeof(buffer)));
}
