// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "ChunkList.hpp"
#include "Tag.hpp"

namespace SF2 {

/**
 A blob of data defined by a Tag. Internally, a chunk can just be a sequence of bytes or it can be a list (bag) of
 other Chunk instances.
 */
class Chunk {
public:

    /**
     Constructor for a chunk of data

     @param tag identifier for this chunk
     @param ptr pointer to the data start
     @param size length of the data
     */
    Chunk(Tag tag, void const* ptr, uint32_t size)
    : tag_{tag}, data_{ptr}, size_{size}, chunks_{} {}

    /**
     Constructor for a list of chunks

     @param tag identifier for this chunk
     @param chunks list of chunks
     */
    Chunk(Tag tag, ChunkList&& chunks) : tag_{tag}, data_{nullptr}, size_{0}, chunks_{std::move(chunks)} {}

    /**
     @returns the chunk ID.
     */
    Tag tag() const { return tag_; }

    /**
     Obtain the pointer to the data blob.
     @returns data blob pointer
     */
    void const* dataPtr() const { return data_; }

    /**
     Obtain the pointer to the data blob as a stream of bytes.
     @returns data blob pointer
     */
    uint8_t const* bytePtr() const { return static_cast<uint8_t const*>(data_); }

    /**
     Obtain the pointer to the data blob as a stream of characters.
     @returns data blob pointer
     */
    char const* charPtr() const { return static_cast<char const*>(data_); }

    /**
     Obtain the size of the data blob.
     @returns data blob size
     */
    uint32_t size() const { return size_; }

    /**
     Obtain iterator that points to the first chunk.
     @returns iterator to the first chunk
     */
    ChunkList::const_iterator begin() const { return chunks_.begin(); }

    /**
     Obtain iterator that points right after the last chunk.
     @returns iterator after the last chunk
     */
    ChunkList::const_iterator end() const { return chunks_.end(); }

    /**
     Search for the first chunk with a given ChunkId
     @param tag identifier for the chunk to look for
     @returns iterator to first chunk or end() if none found.
     */
    ChunkList::const_iterator find(Tag const& tag) const { return chunks_.find(tag); }

    /**
     Search for the *next* chunk with a given ChunkId
     @param it iterator pointing to the first chunk to search
     @param tag identifier for the chunk to look for
     @returns iterator to the next chunk or end() if none found.
     */
    ChunkList::const_iterator findNext(ChunkList::const_iterator it, Tag const& tag) const {
        return chunks_.findNext(it, tag);
    }

    void dump(std::string const& indent) const;

    Chunk(Chunk&& rhs) = default;
    Chunk& operator=(Chunk&& value) = default;

private:
    Chunk(Chunk const& rhs) = delete;
    void* operator new(size_t) = delete;
    void* operator new[](size_t) = delete;

    Tag tag_;
    void const* data_;
    uint32_t size_;
    ChunkList chunks_;
};

}
