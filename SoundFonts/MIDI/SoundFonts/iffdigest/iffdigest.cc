#include "iffdigest.h"
#include <algorithm>
#include <iostream>

/**
 Position bookeeping and a few accessors for locations within a SoundFont data stream. All accessors rigorously check
 for available bytes to protect against buffer overruns, throwing an IFF_FMT_ERROR when there is not enough bytes to
 handle a request.
 */
class IFFParser::Pos {
public:

    /**
     Constructor for a new position.
     @param ptr pointer into SoundFont data to begin working with
     @param size number of bytes available to work with from ptr
     */
    Pos(const char* ptr, size_t size) : pos(ptr), end(ptr + size) {}

    /**
     Obtain the number of bytes remaining to work with
     @returns remaining number of bytes
     */
    size_t remaining() const { return chars(end) - chars(pos); }

    /**
     Obtain a new Pos instance that is advanced from our current position. Shares the same end position.
     @param offset number of bytes to advance.
     @returns new instance
     */
    Pos advance(size_t offset) const { return static_cast<void>(validate(offset)), Pos(*this, offset); }

    /**
     Obtain a new Pos instance that is advanced from our current position *and* has a different end position.
     @param offset number of bytes to advance.
     @param size number of bytes available to parse from the offset position
     */
    Pos advance(size_t offset, size_t size) const {
        return static_cast<void>(validate(offset + size)), Pos(*this, offset, size);
    }

    /**
     Obtain the tag for a chunk we are pointing into

     @returns tag field of current chunk
     */
    IFFChunkTag tag() const { return static_cast<void>(validate(sizeof(uint32_t) * 1)), IFFChunkTag(pos); }

    /**
     Obtain the size for a chunk we are pointing into

     @returns size of current chunk
     */
    uint32_t size() const { return static_cast<void>(validate(sizeof(uint32_t) * 2)), ints(pos)[1]; }

    /**
     Obtain the tag for a list we are pointing into

     @returns tag of current list
     */
    IFFChunkTag list_tag() const { return static_cast<void>(validate(12)), IFFChunkTag(chars(pos) + 8); }

    /**
     Obtain a pointer to the first byte of a data blob

     @returns data pointer
     */
    const char* data(size_t len) const { return static_cast<void>(validate(8 + len)), chars(pos) + 8; }

private:

    Pos(const char* p, const void* e) : pos(p), end(e) {}
    Pos(const Pos& base, size_t offset) : pos(chars(base.pos) + offset), end(base.end) {}
    Pos(const Pos& base, size_t offset, size_t len) : pos(chars(base.pos) + offset), end(chars(pos) + len) {}

    void validate(size_t need) const { if (remaining() < need) throw IFF_FMT_ERROR; }

    static const char* chars(const void* p) { return static_cast<const char*>(p); }
    static const uint32_t* ints(const void* p) { return reinterpret_cast<const uint32_t*>(p); }

    const void* pos;
    const void* end;
};

/**
 Utility class which uses RAII to execute a closure / function when the holding instance is destroyed.
 */
class OnExit
{
public:
    OnExit(std::function<void ()> func) : func_(func) {}
    ~OnExit() { func_(); }

private:
    std::function<void ()> func_;
};

IFFChunk
IFFParser::parseChunk(Pos& pos)
{
    auto len = pos.size();
    auto clen = ((len + 8) + 1) & 0xfffffffe;
    OnExit onExit([&] { pos = pos.advance(clen); });
    return pos.tag() == "LIST"
    ? IFFChunk(pos.list_tag(), parseChunks(pos.advance(12, len - 4)))
    : IFFChunk(pos.tag(), pos.data(len), len);
}

IFFChunkList
IFFParser::parseChunks(Pos pos)
{
    IFFChunkList result;
    while (pos.remaining() > 0) result.push_back(parseChunk(pos));
    return result;
}

IFFParser
IFFParser::parse(const void* data, size_t size)
{
    auto pos = Pos(static_cast<const char*>(data), size);
    if (pos.tag() != "RIFF") throw IFF_FMT_ERROR;

    auto len = pos.size() - 4;
    if (len != size - 12) throw IFF_FMT_ERROR;

    return IFFParser(pos.list_tag(), data, parseChunks(pos.advance(12, len)));
}
