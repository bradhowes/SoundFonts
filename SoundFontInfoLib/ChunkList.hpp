// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <vector>

namespace SF2 {

class Chunk;
class Tag;

/**
 List of Chunk instances. Provides simple searching based on Tag -- O(n) performance
 */
class ChunkList {
public:
    typedef std::vector<Chunk>::const_iterator const_iterator;

    ChunkList() = default;
    ChunkList(ChunkList&& rhs) = default;
    ChunkList& operator=(ChunkList&& rhs) = default;

    void push_back(Chunk&& chunk) { chunks_.emplace_back(std::move(chunk)); }

    /**
     Obtain iterator that points to the first chunk.
     @returns iterator to the first chunk
     */
    const_iterator begin() const { return chunks_.begin(); }

    /**
     Obtain iterator that points right after the last chunk.
     @returns iterator after the last chunk
     */
    const_iterator end() const { return chunks_.end(); }

    /**
     Search for the first chunk with a given IFFChunkId
     @param tag identifier for the chunk to look for
     @returns iterator to first chunk or end() if none found.
     */
    const_iterator find(Tag const& tag) const;

    /**
     Search for the *next* chunk with a given IFFChunkId
     @param it iterator pointing to the first chunk to search
     @param tag identifier for the chunk to look for
     @returns iterator to the next chunk or end() if none found.
     */
    const_iterator findNext(const_iterator it, Tag const& tag) const;

private:
    ChunkList(ChunkList const& rhs) = delete;
    ChunkList& operator=(ChunkList const& rhs) = delete;
    void* operator new(size_t) = delete;
    void* operator new[](size_t) = delete;

    std::vector<Chunk> chunks_;
};

}
