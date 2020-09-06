// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <unistd.h>

#include "Format.hpp"
#include "Tag.hpp"

namespace SF2 {

class Chunk;
class ChunkList;

struct Pos {
    Pos(int fd, size_t pos) : fd_(fd), pos_(pos) {}

    ChunkList makeChunkList() const;
    Chunk makeChunk() const;

    template <typename T>
    Pos readInto(T& buffer, size_t maxCount) const {
        if (::lseek(fd_, pos_, SEEK_SET) != pos_) throw Format::error;
        size_t desired = std::min(sizeof(buffer), maxCount);
        auto result = ::read(fd_, &buffer, desired);
        if (result != desired) throw Format::error;
        return advance(result);
    }

    Pos readInto(void* buffer, size_t count) const {
        if (::lseek(fd_, pos_, SEEK_SET) != pos_) throw Format::error;
        auto result = ::read(fd_, buffer, count);
        if (result != count) throw Format::error;
        return advance(result);
    }

    Pos advance(size_t offset) const { return Pos(fd_, pos_ + offset); }

    friend bool operator <(Pos const& lhs, Pos const& rhs) {
        return lhs.pos_ < rhs.pos_;
    }

private:
    int fd_;
    size_t pos_;
};

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
