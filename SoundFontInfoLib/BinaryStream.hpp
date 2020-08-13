// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "Parser.hpp"

namespace SF2 {

/**
 Manages a pointer into a collection of bytes and provides a mechanism for copying the bytes into an
 object's memory layout for quick instantiation from a SF2 file.
 */
class BinaryStream
{
public:

    /**
     Construct stream.

     - parameter pos: pointer to the first byte to read
     - parameter available: number of bytes available for reading
     */
    BinaryStream(char const* pos, size_t available) : pos_(pos), available_(available) {}

    /**
     Determine if the stream is empty

     - returns: true if empty
     */
    constexpr explicit operator bool() const { return available_ != 0; }

    template <typename T>
    void copyInto(T* destination) {
        if (sizeof(T) != T::size) throw FormatError;
        copyInto(destination, T::size);
    }

    void copyInto(void* destination, size_t size) {
        if (available_ < size) throw FormatError;
        memcpy(destination, pos_, size);
        advance(size);
    }

private:

    void advance(size_t size) {
        if  (available_ < size) throw FormatError;
        pos_ += size;
        available_ -= size;
    }

    char const* pos_;
    size_t available_;
};

}
