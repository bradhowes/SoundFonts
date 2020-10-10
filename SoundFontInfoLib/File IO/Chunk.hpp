// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "Format.hpp"
#include "Pos.hpp"
#include "Tag.hpp"

namespace SF2 {

class Chunk {
public:
    Chunk(Tag tag, uint32_t size, Pos pos) : tag_{tag}, size_{size}, pos_{pos} {}

    Tag tag() const { return tag_; }
    size_t size() const { return size_; }
    Pos begin() const { return pos_; }
    Pos end() const { return pos_.advance(size_); }
    Pos advance() const { return pos_.advance(paddedSize()); }

private:
    uint32_t paddedSize() const { return size_ + ((size_ & 1) ? 1 : 0); }

    Tag const tag_;
    uint32_t const size_;
    Pos const pos_;
};

}
