// Copyright © 2020 Brad Howes. All rights reserved.
//
// Loosely based on iffdigest v0.3 by Andrew C. Bulhak. This code has been modified to *only* work on IFF_FMT_RIFF, and
// it safely parses bogus files by throwing an IFF_FMT_ERROR exception anytime there is an access outside of valid
// memory. Additional cleanup and rework for modern C++ compilers.

#pragma once

#include "Chunk.hpp"
#include "ChunkList.hpp"

namespace SF2 {

/**
 SoundFont file parser.
 */
class Parser {
public:

    /**
     Attempt to parse a SoundFont resource. Any failures to do so will throw a FormatError exception. Note that this really just parses any RIFF
     format. We postpone the SF2 evaluation until the initial loading is done.

     @param data pointer to the first byte of the SoundFont resource to parse
     @param size number of bytes in the resource
     @return Chunk instance representing all of the items in the given data
     */
    static Chunk parse(void const* data, size_t size);

private:
    Parser(Parser const& rhs) = delete;
    Parser& operator=(Parser const& rhs) = delete;
    void* operator new(size_t) = delete;
    void* operator new[](size_t) = delete;

    struct Pos;
    static Chunk parseChunk(Pos& pos);
    static ChunkList parseChunks(Pos pos);
};

}
