// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <map>
#include <vector>

#include "Render/Preset.hpp"

namespace SF2::IO { class File; }
namespace SF2::Render::Engine {

/**
 Collection of all of the Entity::Preset instances in an SF2 file, each of which is wrapped in a
 Render::Preset instance for use during audio rendering.
 */
class PresetCollection
{
public:

  /**
   Representation of a key for a preset that is made up of the bank and program values used to call it up. The
   collection will store the presets in increasing order based on these values.
   */
  struct BankProgram {
    int bank;
    int program;

    friend bool operator ==(const BankProgram& lhs, const BankProgram& rhs) { return lhs.bank == rhs.bank; }

    friend bool operator <(const BankProgram& lhs, const BankProgram& rhs) {
      return lhs.bank < rhs.bank || (lhs.bank == rhs.bank && lhs.program < rhs.program);
    }
  };

  PresetCollection() = default;

  /**
   Build a collection using the contents of the given file

   @param file the data to use to build the preset collection
   */
  void build(const IO::File& file) {
    auto count = file.presets().size();
    instruments_.build(file);
    presets_.clear();
    if (presets_.capacity() < count) presets_.reserve(count);

    // The order of the presets from the file is unknown. We visit each one and add the config index to a map.
    // Then we iterate over the map and create Preset entries that are sorted by increasing bank and program number.
    std::map<BankProgram, size_t> ordering;
    for (const Entity::Preset& configuration : file.presets().slice(0, count)) {
      BankProgram key{configuration.bank(), configuration.program()};
      auto [pos, success] = ordering.insert(std::pair(key, ordering.size()));
      if (!success) throw std::runtime_error("duplicate bank/program pair");
    }

    // Build the collection in increasing bank/program order.
    auto presetConfigs = file.presets();
    for (auto [key, value] : ordering) {
      presets_.emplace_back(file, instruments_, presetConfigs[value]);
    }
  }

  /// Obtain the number of presets in the collection.
  size_t size() const { return presets_.size(); }

  /// Obtain the preset at a given index.
  const Preset& operator[](size_t index) const { return presets_[index]; }

private:
  std::vector<Preset> presets_{};
  InstrumentCollection instruments_;
};

} // namespace SF2::Render
