// Copyright © 2021 Brad Howes. All rights reserved.

#pragma once

#include <functional>
#include <list>
#include <vector>

#include "Render/Engine/Tick.hpp"
#include "Render/Engine/ListNodeAllocator.hpp"

namespace SF2::Render::Engine {

/**
 Least-recently used cache of active voices. All operations on the cache are O(1) but each entry in the
 cache is 3x the size of the value being held (size_t). 
 */
class OldestActiveVoiceCache
{
public:

  OldestActiveVoiceCache(size_t maxVoiceCount)
  : lru_(ListNodeAllocator<size_t>(maxVoiceCount))
  {
    for (size_t voiceIndex = 0; voiceIndex < maxVoiceCount; ++voiceIndex) {
      positions_.push_back(lru_.end());
    }
  }

  void add(size_t voiceIndex) {
    if (voiceIndex >= positions_.size()) throw std::runtime_error("invalid voice index");
    if (positions_[voiceIndex] != lru_.end()) throw std::runtime_error("voice in cache");
    positions_[voiceIndex] = lru_.insert(lru_.begin(), voiceIndex);
  }

  void remove(size_t voiceIndex) {
    if (voiceIndex >= positions_.size()) throw std::runtime_error("invalid voice index");
    if (positions_[voiceIndex] == lru_.end()) throw std::runtime_error("voice not in cache");
    lru_.erase(positions_[voiceIndex]);
    positions_[voiceIndex] = lru_.end();
  }

  size_t takeOldest() {
    if (lru_.empty()) throw std::runtime_error("cache is empty");
    size_t oldest = lru_.back();
    positions_[oldest] = lru_.end();
    lru_.pop_back();
    return oldest;
  }

  bool empty() const { return lru_.empty(); }

private:
  std::list<size_t, ListNodeAllocator<size_t>> lru_;
  std::vector<std::list<size_t>::iterator> positions_{};
};

} // end namespace SF2::Render::Engine
