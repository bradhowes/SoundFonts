//  iffdigest.h  C++ classes for a simple (in-memory) RIFF file parser.

#ifndef __IFFPARSER_H
#define __IFFPARSER_H

#include <list>
#include <string>

/**
 We only operate with IFF_FMT_RIFF.
 */
enum IFFFormat { IFF_FMT_IFF85, IFF_FMT_RIFF, IFF_FMT_ERROR };

/**
 Each RIFF chunk or blob has a 4-character tag that uniquely identifies the contents of the chunk. This is also a 4-byte
 integer.
 */
class IFFChunkTag {
public:
    IFFChunkTag(uint32_t tag) : tag_(tag) {}
    IFFChunkTag(const char* s) : IFFChunkTag(*(reinterpret_cast<const uint32_t*>(s))) {}
    IFFChunkTag(const void* s) : IFFChunkTag(static_cast<const char*>(s)) {}

    bool operator ==(const IFFChunkTag& rhs) const { return tag_ == rhs.tag_; }
    bool operator !=(const IFFChunkTag& rhs) const { return tag_ != rhs.tag_; }

    std::string toString() const { return std::string(reinterpret_cast<const char*>(&tag_), 4); }

private:
    uint32_t tag_;
};

class IFFChunk;

typedef std::list<IFFChunk>::iterator IFFChunkIterator;

/**
 List of IFFChunk instances. Provides simple searching based on IFFChunkId -- O(n) performance
 */
class IFFChunkList: public std::list<IFFChunk> {
public:

    /**
     Search for the first chunk with a given IFFChunkId
     @param tag identifier for the chunk to look for
     @returns iterator to first chunk or end() if none found.
     */
    IFFChunkIterator findChunk(const IFFChunkTag& tag);

    /**
     Search for the *next* chunk with a given IFFChunkId
     @param it iterator pointing to the first chunk to search
     @param tag identifier for the chunk to look for
     @returns iterator to the next chunk or end() if none found.
     */
    IFFChunkIterator findNextChunk(IFFChunkIterator it, const IFFChunkTag& tag);
};

/**
 A blob of data defined by a IFFChunkId. Internally, a chunk can just be a sequence of bytes or it can be a list of
 other IFFChunk instances.
 */
class IFFChunk {
public:

    /**
     Constructor for a chunk of data

     @param tag identifier for this chunk
     @param ptr pointer to the data start
     @param size length of the data
     */
    IFFChunk(const IFFChunkTag& tag, const char* ptr, uint32_t size)
    : tag_(tag), kind_(IFF_CHUNK_DATA), data_(ptr), size_(size), chunks_() {}

    /**
     Constructor for a list of chunks

     @param tag identifier for this chunk
     @param list list of chunks
     */
    IFFChunk(const IFFChunkTag& tag, IFFChunkList&& list)
    : tag_(tag), kind_(IFF_CHUNK_LIST), data_(nullptr), size_(0), chunks_(list) {}

    /**
     @returns the chunk ID.
     */
    const IFFChunkTag& tag() const { return tag_; }

    /**
     Obtain the pointer to the data blob. Only valid if kind_ == IFF_CHUNK_DATA
     @returns data blob pointer
     */
    const char* dataPtr() const { return data_; }

    /**
     Obtain the size of the data blob. Only valid if kind_ == IFF_CHUNK_DATA
     @returns data blob size
     */
    uint32_t size() const { return size_; }

    /**
     Obtain iterator that points to the first chunk. Only valid if kind_ == IFF_CHUNK_LIST
     @returns iterator to the first chunk
     */
    IFFChunkIterator begin() { return chunks_.begin(); }

    /**
     Obtain iterator that points right after the last chunk. Only valid if kind_ == IFF_CHUNK_LIST
     @returns iterator after the last chunk
     */
    IFFChunkIterator end() { return chunks_.end(); }

    /**
     Search for the first chunk with a given IFFChunkId
     @param tag identifier for the chunk to look for
     @returns iterator to first chunk or end() if none found.
     */
    IFFChunkIterator find(const IFFChunkTag& tag) { return chunks_.findChunk(tag); }

    /**
     Search for the *next* chunk with a given IFFChunkId
     @param it iterator pointing to the first chunk to search
     @param tag identifier for the chunk to look for
     @returns iterator to the next chunk or end() if none found.
     */
    IFFChunkIterator findNext(IFFChunkIterator it, const IFFChunkTag& tag) { return chunks_.findNextChunk(it, tag); }

private:
    IFFChunkTag tag_;
    enum { IFF_CHUNK_DATA, IFF_CHUNK_LIST } kind_;
    const char* data_;
    uint32_t size_;
    IFFChunkList chunks_;
};

/**
 SoundFont file parser
 */
class IFFParser {
public:

    /**
     Attempt to parse a SoundFont resource. Any failures to do so will throw an IFF_FMT_ERROR exception.

     @param data pointer to the first byte of the SoundFont resource to parse
     @param size number of bytes in the resource
     */
    static IFFParser parse(const void* data, size_t size);

    /**
     Obtain the tag for the file.

     @returns IFFChunkId tag for the file.
     */
    const IFFChunkTag& tag() const { return tag_; }

    /**
     Obtain iterator to the first chunk in the resource.

     @returns iterator to first chunk.
     */
    IFFChunkIterator begin() { return chunks_.begin(); }

    /**
     Obtain iterator to the position after the last chunk in the resource.

     @returns iterator to position after the last chunk
     */
    IFFChunkIterator end() { return chunks_.end(); }

    /**
     Locate the first occurance of a chunk with the given tag value.

     @param tag the tag to look for
     @returns iterator to found chunk or end()
     */
    IFFChunkIterator find(const IFFChunkTag& tag) { return chunks_.findChunk(tag); }

    /**
     Locate the first occurance of a chunk with the given tag value.

     @param it iterator pointing to the first chunk to search
     @param tag the tag to look for

     @returns iterator to found chunk or end()
     */
    IFFChunkIterator findNext(IFFChunkIterator it, const IFFChunkTag& tag) { return chunks_.findNextChunk(it, tag); }

private:
    IFFParser(const IFFChunkTag& tag, const void* raw, const IFFChunkList& chunks)
    : tag_(tag), raw_(raw), chunks_(chunks) {}

    IFFChunkTag tag_;
    const void* raw_;
    IFFChunkList chunks_;

    class Pos;
    static IFFChunk parseChunk(Pos& pos);
    static IFFChunkList parseChunks(Pos pos);
};

inline IFFChunkIterator
IFFChunkList::findNextChunk(IFFChunkIterator from, const IFFChunkTag& tag)
{
    return find_if(++from, end(), [&] (const IFFChunk& value) { return value.tag()== tag; });
}

inline IFFChunkIterator
IFFChunkList::findChunk(const IFFChunkTag& tag)
{
    return find_if(begin(), end(), [&] (const IFFChunk& value) { return value.tag() == tag; });
}

#endif
