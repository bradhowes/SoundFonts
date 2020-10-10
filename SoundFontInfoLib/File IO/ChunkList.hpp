// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "Chunk.hpp"

namespace SF2 {

class ChunkList : public Chunk {
public:

    ChunkList(Tag tag, uint32_t size, Tag kind, Pos pos) : Chunk(tag, size, pos), kind_{kind} {}

    Tag kind() const { return kind_; }

    Pos begin() const { return dataPos(); }
    Pos end() const { return dataEnd(); }

private:
    Tag kind_;
};

}
