// Copyright © 2020 Brad Howes. All rights reserved.

#ifndef Tag_hpp
#define Tag_hpp

#include <string>

namespace SF2 {

/**
 Each RIFF chunk or blob has a 4-character tag that uniquely identifies the contents of the chunk. This is also a 4-byte
 integer.
 */
class Tag {
public:
    Tag(uint32_t tag) : tag_(tag) {}
    Tag(const char* s) : Tag(*(reinterpret_cast<const uint32_t*>(s))) {}
    Tag(const void* s) : Tag(static_cast<const char*>(s)) {}

    bool operator ==(const Tag& rhs) const { return tag_ == rhs.tag_; }
    bool operator !=(const Tag& rhs) const { return tag_ != rhs.tag_; }

    uint32_t toInt() const { return tag_; }
    std::string toString() const { return std::string(reinterpret_cast<const char*>(&tag_), 4); }

    static const Tag riff;
    static const Tag list;
    static const Tag sfbk;
    static const Tag info;
    static const Tag sdta;

    static const Tag pdta;
    static const Tag ifil;
    static const Tag isng;
    static const Tag inam;
    static const Tag irom;

    static const Tag iver;
    static const Tag icrd;
    static const Tag ieng;
    static const Tag iprd;
    static const Tag icop;

    static const Tag icmt;
    static const Tag isft;
    static const Tag snam;
    static const Tag smpl;
    static const Tag phdr;

    static const Tag pbag;
    static const Tag pmod;
    static const Tag pgen;
    static const Tag inst;
    static const Tag ibag;

    static const Tag imod;
    static const Tag igen;
    static const Tag shdr;
    static const Tag sm24;
    static const Tag unkn;

private:
    uint32_t tag_;
};

}

#endif /* Tag_hpp */
