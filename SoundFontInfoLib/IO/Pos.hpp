// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <unistd.h>

#include "IO/Format.hpp"

namespace SF2 {
namespace IO {

class Chunk;
class ChunkList;

/**
 Representation of a file position. Instances of this type are immutable by design. It has methods that will generate
 instances with new position values.
 */
struct Pos {

    /**
     Constructor

     @param fd the file descriptor to read from
     @param pos the current location in the file being processed
     @param end the end of the file being processed
     */
    Pos(int fd, size_t pos, size_t end) : fd_{fd}, pos_{pos}, end_{end} {}

    /**
     Create a new ChunkList from the current position.

     @returns new ChunkList instance
     */
    ChunkList makeChunkList() const;

    /**
     Create a new Chunk from the current position.

     @returns new Chunk instance
     */
    Chunk makeChunk() const;

    /**
     Read bytes from the file at the current position and place them into the given buffer.

     @param buffer the destination for the bytes

     @returns new Pos instance for the next bytes in the file
     */
    template <typename T>
    Pos readInto(T& buffer) const {
        return readInto(&buffer, sizeof(buffer));
    }

    /**
     Read bytes from the file at the current position and place them into the given buffer.

     @param buffer the destination for the bytes
     @param maxCount the maximum number of bytes to read, even if the size of the buffer is larger

     @returns new Pos instance for the next bytes in the file
     */
    template <typename T>
    Pos readInto(T& buffer, size_t maxCount) const {
        return readInto(&buffer, std::min(sizeof(buffer), maxCount));
    }

    /**
     Read bytes from the file at the current position and place them into the given buffer.

     @param buffer the destination for the bytes
     @param count the number number of bytes to read

     @returns new Pos instance for the next bytes in the file
     */
    Pos readInto(void* buffer, size_t count) const {
        if (::lseek(fd_, pos_, SEEK_SET) != pos_) throw Format::error;
        auto result = ::read(fd_, buffer, count);
        if (result != count) throw Format::error;
        return advance(result);
    }

    /**
     Obtain the file offset represented by this instance

     @returns file offset
     */
    constexpr size_t offset() const { return pos_; }

    /// @returns number of bytes available to read at this position in the file.
    constexpr size_t available() const { return end_ - pos_; }

    /**
     Calculate new Pos value after advancing `offset` bytes forward.

     @param offset the number of bytes to advance
     @returns new Pos instance for the next bytes in the file
     */
    Pos advance(size_t offset) const { return Pos(fd_, std::min(pos_ + offset, end_), end_); }

    /// @returns true if Pos is invalid
    constexpr explicit operator bool() const { return fd_ < 0 || pos_ >= end_; }

    /// @returns true if first Pos value is less than the second one
    friend bool operator <(const Pos& lhs, const Pos& rhs) { return lhs.pos_ < rhs.pos_; }

private:
    int fd_;
    size_t pos_;
    size_t end_;
};

}
}
