// Copyright © 2020 Brad Howes. All rights reserved.

#include <algorithm>
#include <iostream>

#include "Parser.hpp"

using namespace SF2;

/**
 Position bookeeping and a few accessors for locations within a SoundFont data stream. All accessors rigorously check
 for available bytes to protect against buffer overruns, throwing an IFF_FMT_ERROR when there is not enough bytes to
 handle a request.
 */
struct Parser::Pos {
    static auto chars(void const* p) -> auto { return static_cast<char const*>(p); }
    static auto ints(void const* p) -> auto { return reinterpret_cast<uint32_t const*>(p); }

    /**
     Constructor for a new position.
     @param ptr pointer into SoundFont data to begin working with
     @param size number of bytes available to work with from ptr
     */
    Pos(char const* ptr, size_t size) : pos(ptr), end(ptr + size) {}

    /**
     Obtain the number of bytes remaining to work with
     @returns remaining number of bytes
     */
    auto remaining() const -> auto { return chars(end) - chars(pos); }

    /**
     Obtain a new Pos instance that is advanced from our current position. Shares the same end position.
     @param offset number of bytes to advance.
     @returns new instance
     */
    auto advance(size_t offset) const -> auto { validate(offset); return Pos(*this, offset); }

    /**
     Obtain a new Pos instance that is advanced from our current position *and* has a different end position.
     @param offset number of bytes to advance.
     @param size number of bytes available to parse from the offset position
     */
    auto advance(size_t offset, size_t size) const -> auto { validate(offset + size); return Pos(*this, offset, size); }

    /**
     Obtain the tag for a chunk we are pointing into

     @returns tag field of current chunk
     */
    auto tag() const -> auto { validate(sizeof(uint32_t) * 1); return Tag(pos); }

    /**
     Obtain the size for a chunk we are pointing into

     @returns size of current chunk
     */
    auto size() const -> auto { validate(sizeof(uint32_t) * 2); return ints(pos)[1]; }

    /**
     Obtain the tag for a list we are pointing into

     @returns tag of current list
     */
    auto list_tag() const -> auto { validate(12); return Tag(chars(pos) + 8); }

    /**
     Obtain a pointer to the first byte of a data blob

     @returns data pointer
     */
    auto data(size_t len) const -> auto { validate(8 + len); return chars(pos) + 8; }

private:

    Pos(char const* p, void const* e) : pos(p), end(e) {}
    Pos(Pos const& base, size_t offset) : pos(chars(base.pos) + offset), end(base.end) {}
    Pos(Pos const& base, size_t offset, size_t len) : pos(chars(base.pos) + offset), end(chars(pos) + len) {}

    /**
     Make sure that there is enough bytes to satisfy some data request. Throws IFF_FMT_ERROR if there is not enough.
     @param need number of bytes to consume
     */
    void validate(size_t need) const { if (remaining() < need) throw FormatError; }

    void const* pos;
    void const* end;
};

/**
 Utility class which uses RAII to execute a closure / function when the holding instance is destroyed.
 */
struct Defer
{
    explicit Defer(std::function<void ()>&& func) : func_{std::move(func)} {}
    ~Defer() { func_(); }
    std::function<void ()> func_;
};

Chunk
Parser::parseChunk(Pos& pos)
{
    auto len = pos.size();
    auto clen = ((len + 8) + 1) & 0xfffffffe;
    Defer defer([&] { pos = pos.advance(clen); });
    return pos.tag() == Tag(Tags::list)
    ? Chunk(pos.list_tag(), parseChunks(pos.advance(12, len - 4)))
    : Chunk(pos.tag(), pos.data(len), len);
}

ChunkList
Parser::parseChunks(Pos pos)
{
    ChunkList result;
    while (pos.remaining() > 0) result.push_back(parseChunk(pos));
    return result;
}

Chunk
Parser::parse(void const* data, size_t size)
{
    auto pos = Pos(static_cast<char const*>(data), size);
    if (pos.tag() != Tag(Tags::riff)) throw FormatError;

    // Check that the total size given of the given data matches what is recorded in the header of the top-level
    // chunk.
    auto len = pos.size() - 4;
    if (len != size - 12) throw FormatError;

    return Chunk(pos.list_tag(), parseChunks(pos.advance(12, len)));
}
