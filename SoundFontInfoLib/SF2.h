// Copyright (c) 2019 Brad Howes. All rights reserved.
//
// Loosely based on iffdigest v0.3 by Andrew C. Bulhak. This code has been modified to *only* work on IFF_FMT_RIFF, and
// it safely parses bogus files by throwing an IFF_FMT_ERROR exception anytime there is an access outside of valid
// memory. Additional cleanup and rework for modern C++ compilers.

#ifndef __IFFPARSER_H
#define __IFFPARSER_H

#include <list>
#include <string>

#include "Chunk.hpp"
#include "ChunkList.hpp"
#include "Tag.hpp"

namespace SF2 {

/**
 We only operate with FormatRIFF.
 */
enum Format { FormatRIFF, FormatError };

/**
 SoundFont file parser
 */
class Parser {
public:

    /**
     Attempt to parse a SoundFont resource. Any failures to do so will throw an IFF_FMT_ERROR exception.

     @param data pointer to the first byte of the SoundFont resource to parse
     @param size number of bytes in the resource
     */
    static Chunk parse(const void* data, size_t size);

private:
    struct Pos;
    static Chunk parseChunk(Pos& pos);
    static ChunkList parseChunks(Pos pos);
};

}

#endif
