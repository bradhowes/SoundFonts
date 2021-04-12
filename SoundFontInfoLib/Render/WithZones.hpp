// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "IO/File.hpp"

#include "Render/Zone.hpp"
#include "Render/ZoneCollection.hpp"

namespace SF2 {
namespace Render {

/**
 Base class for entities that contain a collection of zones.
 */
template <typename T, typename E>
class WithZones
{
public:
    using ZoneType = T;
    using EntityType = E;
    using WithZoneCollection = ZoneCollection<ZoneType>;

    /// @returns true if the instrument has a global zone
    bool hasGlobalZone() const { return zones_.hasGlobal(); }

    /// @returns the instrument's global zone or nullptr if there is none
    const ZoneType* globalZone() const { return zones_.global(); }

    const WithZoneCollection& zones() const { return zones_; }

    /// @returns the instrument's entity from the SF2 file
    const EntityType& configuration() const { return configuration_; }

protected:
    WithZones(size_t zoneCount, const EntityType& configuration) :
    zones_{zoneCount}, configuration_{configuration} {}

    WithZoneCollection zones_;
    const EntityType& configuration_;
};

} // namespace Render
} // namespace SF2
