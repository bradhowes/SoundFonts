// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "Format.hpp"
#include "Pos.hpp"
#include "Tag.hpp"

namespace SF2 {

class Chunk {
public:
    Chunk(Tag tag, uint32_t size, Pos pos) : tag_{tag}, size_{size}, dataPos_{pos} {}

    Tag tag() const { return tag_; }
    size_t dataSize() const { return size_; }

    Pos dataPos() const { return dataPos_; }
    Pos dataEnd() const { return dataPos_.advance(size_); }

    Pos next() const { return dataPos_.advance(paddedSize()); }

private:
    uint32_t paddedSize() const { return size_ + ((size_ & 1) ? 1 : 0); }

    Tag tag_;
    uint32_t size_;
    Pos dataPos_;
};

}
