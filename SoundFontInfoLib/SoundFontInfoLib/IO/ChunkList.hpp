// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "IO/Chunk.hpp"

namespace SF2 {
namespace IO {

/**
 Like `Chunk`, this class represents a tagged chunk of a file, but this is also a collection of similar items all with
 the same `kind` tagged 4-byte value.
 */
class ChunkList : public Chunk {
public:

    /**
     Constructor

     @param tag the container's Tag type
     @param size the number of bytes used by the chunk list
     @param kind the Tag type for the elements in the chunk list
     @param pos the file position where the first item in the list is to be found
     */
    ChunkList(Tag tag, uint32_t size, Tag kind, Pos pos) : Chunk(tag, size, pos), kind_{kind} {}

    /**
     Obtain the Tag type for the elements held in the container

     @return Tag type
     */
    Tag kind() const { return kind_; }

private:
    Tag kind_;
};

} // end namespace IO
} // end namespace SF2
