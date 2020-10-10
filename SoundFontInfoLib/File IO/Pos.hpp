// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <unistd.h>

#include "Format.hpp"

namespace SF2 {

class Chunk;
class ChunkList;

struct Pos {
    Pos(int fd, size_t pos, size_t end) : fd_{fd}, pos_{pos}, end_{end} {}

    ChunkList makeChunkList() const;
    Chunk makeChunk() const;

    template <typename T>
    Pos readInto(T& buffer) const {
        return readInto(&buffer, sizeof(buffer));
    }

    template <typename T>
    Pos readInto(T& buffer, size_t maxCount) const {
        return readInto(&buffer, std::min(sizeof(buffer), maxCount));
    }

    Pos readInto(void* buffer, size_t count) const {
        if (::lseek(fd_, pos_, SEEK_SET) != pos_) throw Format::error;
        auto result = ::read(fd_, buffer, count);
        if (result != count) throw Format::error;
        return advance(result);
    }

    Pos advance(size_t offset) const { return Pos(fd_, std::min(pos_ + offset, end_), end_); }

    /// Return number of bytes available to read at this position in the file.
    constexpr size_t available() const { return end_ - pos_; }

    /// Return true if Pos is invalid
    constexpr explicit operator bool() const { return fd_ < 0 || pos_ >= end_; }

    friend bool operator <(Pos const& lhs, Pos const& rhs) { return lhs.pos_ < rhs.pos_; }

private:
    int fd_;
    size_t pos_;
    size_t end_;
};

}
