// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <functional>
#include <vector>

#include "Entity/Bag.hpp"
#include "Entity/Generator/Generator.hpp"
#include "Entity/Modulator/Modulator.hpp"
#include "IO/ChunkItems.hpp"
#include "IO/File.hpp"
#include "Render/Configuration.hpp"

namespace SF2 {
namespace Render {

/**
 Templated collection of zones. A non-global zone defines a range of MIDI keys and/or velocities over which it operates.
 The first zone can be a `global` zone. The global zone defines the configuration settings that apply to all other zones.
 */
template <typename Kind>
class ZoneCollection
{
public:
    using Matches = typename std::vector<std::reference_wrapper<Kind const>>;

    /**
     Construct a new collection that expects to hold the given number of elements.
     */
    explicit ZoneCollection(size_t size) : zones_{} { zones_.reserve(size); }

    /**
     Locate the zone(s) that match the given key/velocity pair.
     */
    Matches find(int key, int velocity) const {
        Matches matches;
//        typename Super::const_iterator pos = this->begin();
//        if (this->hasGlobal()) ++pos;
//        std::copy_if(pos, this->end(), std::back_inserter(matches), [=](const Zone& zone) {
//            return zone.appliesTo(key, velocity);
//        });
        return matches;
    }

    bool hasGlobal() const { return zones_.empty() ? false : zones_.front().isGlobal(); }

    Kind const* global() const { return hasGlobal() ? &zones_.front() : nullptr; }

    template<class... Args>
    void add(Args&&... values) { zones_.emplace_back(std::forward<Args>(values)...); }

private:
    std::vector<Kind> zones_;
};

} // namespace Render
} // namespace SF2
