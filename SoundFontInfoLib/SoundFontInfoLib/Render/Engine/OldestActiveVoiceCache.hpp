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
 cache is 3x the size of the value being held (size_t) + an iterator that points to the entry in the cache.
 Internally, the cache consists of a linked list which keeps the voices ordered by their time of activation. For fast
 removal within the linked list, there is a separate vector of iterators that points to each entry in the linked list.
 Changes to a std::list do not invalidate iterators that point to other nodes besides the one being added or removed.
 This vector is indexed by the voice index that is unique to each voice.
 */
class OldestActiveVoiceCache
{
public:

  /**
   Constructor. Allocates nodes in the cache for a maximum number of voices.

   @param maxVoiceCount the number of voices to support
   */
  OldestActiveVoiceCache(size_t maxVoiceCount)
  : leastRecentlyUsed_(ListNodeAllocator<size_t>(maxVoiceCount))
  {
    for (size_t voiceIndex = 0; voiceIndex < maxVoiceCount; ++voiceIndex) {
      iterators_.push_back(leastRecentlyUsed_.end());
    }
  }

  /**
   Add a voice to the cache. It must not already be in the cache.

   @param voiceIndex the unique ID of the voice
   */
  void add(size_t voiceIndex) {
    if (voiceIndex >= iterators_.size()) throw std::runtime_error("invalid voice index");
    if (iterators_[voiceIndex] != leastRecentlyUsed_.end()) throw std::runtime_error("voice already in cache");

    // Insert the voice at the beginning of the linked list. Record an iterator to it.
    iterators_[voiceIndex] = leastRecentlyUsed_.insert(leastRecentlyUsed_.begin(), voiceIndex);
  }

  /**
   Remove a voice from the cache. It must be in the cache.

   @param voiceIndex the unique ID of the voice
   */
  void remove(size_t voiceIndex) {
    if (voiceIndex >= iterators_.size()) throw std::runtime_error("invalid voice index");
    if (iterators_[voiceIndex] == leastRecentlyUsed_.end()) throw std::runtime_error("voice not in cache");

    // Remove voice by using the iterator that points to it. Reset iterator for voice to 'unused' state.
    leastRecentlyUsed_.erase(iterators_[voiceIndex]);
    iterators_[voiceIndex] = leastRecentlyUsed_.end();
  }

  /**
   Remove the oldest voice. There must be at least one active voice in the cache (really, the size of the list should
   be the same as the size of the vector).

   @returns index of the voice that was taken from the cache
   */
  size_t takeOldest() {
    if (leastRecentlyUsed_.empty()) throw std::runtime_error("cache is empty");
    size_t oldest = leastRecentlyUsed_.back();
    iterators_[oldest] = leastRecentlyUsed_.end();
    leastRecentlyUsed_.pop_back();
    return oldest;
  }

  /// @returns true if the cache is empty
  bool empty() const { return leastRecentlyUsed_.empty(); }

  /// @returns the number of voices in the cache (since C++11 this is guaranteed to be O(1)).
  size_t size() const { return leastRecentlyUsed_.size(); }

private:
  std::list<size_t, ListNodeAllocator<size_t>> leastRecentlyUsed_;
  std::vector<std::list<size_t>::iterator> iterators_{};
};

} // end namespace SF2::Render::Engine
