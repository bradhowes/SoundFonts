// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <string>

namespace SF2::IO {

/**
 Each RIFF chunk or blob has a 4-character tag that uniquely identifies the contents of the chunk. This is also a 4-byte
 unsigned integer.
 */
class Tag {
public:
  Tag(uint32_t tag) : tag_{tag} {}

  uint32_t rawValue() const { return tag_; }

  bool operator ==(const Tag& rhs) const { return tag_ == rhs.tag_; }
  bool operator !=(const Tag& rhs) const { return tag_ != rhs.tag_; }

  std::string toString() const { return std::string(reinterpret_cast<char const*>(&tag_), 4); }

private:
  uint32_t tag_;
};

inline constexpr uint32_t Pack4Chars(const char* c)
{
  return ((uint32_t)(c[3])) << 24 | ((uint32_t)(c[2])) << 16 | ((uint32_t)(c[1])) << 8 | ((uint32_t)(c[0]));
}

/**
 Global list of all tags defined in the SF2 specification.
 */
enum Tags {
  riff = Pack4Chars("RIFF"),
  list = Pack4Chars("LIST"),
  sfbk = Pack4Chars("sfbk"),
  info = Pack4Chars("INFO"),
  sdta = Pack4Chars("sdta"),

  pdta = Pack4Chars("pdta"),
  ifil = Pack4Chars("ifil"),
  isng = Pack4Chars("isng"),
  inam = Pack4Chars("INAM"),
  irom = Pack4Chars("irom"),  // info ids (1st byte of info strings

  iver = Pack4Chars("iver"),
  icrd = Pack4Chars("ICRD"),
  ieng = Pack4Chars("IENG"),
  iprd = Pack4Chars("IPRD"),  // more info ids
  icop = Pack4Chars("ICOP"),

  icmt = Pack4Chars("ICMT"),
  istf = Pack4Chars("ISTF"),  // and yet more info ids
  snam = Pack4Chars("snam"),  // sample name
  smpl = Pack4Chars("smpl"),  // binary samples
  phdr = Pack4Chars("phdr"),  // preset definition

  pbag = Pack4Chars("pbag"),  // collection of generators and modulators for a preset
  pmod = Pack4Chars("pmod"),  // preset modulators
  pgen = Pack4Chars("pgen"),  // preset generators including preset IDs
  inst = Pack4Chars("inst"),  // instrument definition
  ibag = Pack4Chars("ibag"),  // collection of generators and modulators for an instrument

  imod = Pack4Chars("imod"),  // instrumen modulators
  igen = Pack4Chars("igen"),  // instrument generators including reference to sample IDs
  shdr = Pack4Chars("shdr"),  // sample info
  sm24 = Pack4Chars("sm24"),  // sample extensions for 24-bit audio
  unkn = Pack4Chars("????"),
};

} // end namespace SF2::IO
