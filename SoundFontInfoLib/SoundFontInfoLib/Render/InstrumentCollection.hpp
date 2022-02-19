// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <vector>

#include "Render/Instrument.hpp"

namespace SF2::IO { class File; }
namespace SF2::Render {

/**
 Collection of all of the Entity::Instrument instances in an SF2 file, each of which is wrapped in a
 Render::Instrument instance for use during audio rendering.
 */
class InstrumentCollection
{
public:

  InstrumentCollection() = default;

  explicit InstrumentCollection(const IO::File& file) {
    build(file);
  }

  /**
   Construct a new collection using contents from the given file.

   @param file the file to build with
   */
  void build(const IO::File& file) {
    auto count = file.instruments().size();
    instruments_.clear();
    if (count > instruments_.capacity()) instruments_.reserve(count);
    for (const Entity::Instrument& configuration : file.instruments().slice(0, count)) {
      instruments_.emplace_back(file, configuration);
    }
  }

#ifdef DEBUG
  const Instrument& operator[](size_t index) const { return instruments_.at(index); }
#else
  const Instrument& operator[](size_t index) const { return instruments_[index]; }
#endif

private:
  std::vector<Instrument> instruments_{};
};

} // namespace SF2::Render
