// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <functional>
#include <vector>

#include "Entity/Bag.hpp"
#include "Entity/Generator/Generator.hpp"
#include "Entity/Modulator/Modulator.hpp"
#include "IO/ChunkItems.hpp"
#include "IO/File.hpp"

namespace SF2 {
namespace Render {

/**
 Templated collection of zones. A non-global zone defines a range of MIDI keys and/or velocities over which it operates.
 The first zone can be a `global` zone. The global zone defines the configuration settings that apply to all other
 zones.
 */
template <typename Kind>
class ZoneCollection
{
public:
    using Matches = typename std::vector<std::reference_wrapper<Kind const>>;

    /**
     Construct a new collection that expects to hold the given number of elements.

     @param zoneCount the number of zones that the collection will hold
     */
    explicit ZoneCollection(size_t zoneCount) : zones_{} { zones_.reserve(zoneCount); }

    /// @returns number of zones in the collection (include the optional global one)
    size_t size() const { return zones_.size(); }

    /**
     Locate the zone(s) that match the given key/velocity pair.

     @param key the MIDI key to filter on
     @param velocity the MIDI velocity to filter on
     @returns a vector of matching zones
     */
    Matches filter(UByte key, UByte velocity) const {
        Matches matches;
        auto pos = zones_.begin();
        if (hasGlobal()) ++pos;
        std::copy_if(pos, zones_.end(), std::back_inserter(matches),
                     [key, velocity](const Zone& zone) { return zone.appliesTo(key, velocity); });
        return matches;
    }

    /// @returns true if first zone in collection is a global zone
    bool hasGlobal() const { return zones_.empty() ? false : zones_.front().isGlobal(); }

    /// @returns get pointer to global zone or nullptr if there is not one
    const Kind* global() const { return hasGlobal() ? &zones_.front() : nullptr; }

    /**
     Add a zone with the given args. Note that empty zones (no generators and no modulators) are dropped, as are any
     global zones that are not the first zone.

     @param file the SF2 file with the entities to use
     @param bag the definition for the Zone
     @param values additional arguments for the Zone construction
     */
    template<class... Args>
    void add(const IO::File& file, const Entity::Bag& bag, Args&&... values) {
        // Per spec, skip empty zone definitions
        if (bag.generatorCount() == 0 && bag.modulatorCount() == 0) return;
        zones_.emplace_back(file, bag, std::forward<Args>(values)...);
        // Per spec, only allow one global zone and it must be the first one
        if (zones_.size() > 1 && zones_.back().isGlobal()) {
            zones_.pop_back();
        }
    }

private:
    std::vector<Kind> zones_;
};

} // namespace Render
} // namespace SF2
