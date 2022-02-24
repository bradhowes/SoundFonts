// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <optional>

#include "IO/File.hpp"

#include "Render/Zone/Zone.hpp"
#include "Render/Zone/Collection.hpp"

namespace SF2::Render::Zone {

/**
 Base class for entities that contain a collection of zones (there are two: Render::Preset and Render::Instrument).
 Contains common properties and methods shared between these two classes.

 - `T` is an SF2::Zone class (PresetZone or InstrumentZone) to hold in the collection
 - `E` is the SF2::Entity class that defines the zone configuration in the SF2 file.

 Must be derived from.
 */
template <typename T, typename E>
class WithCollectionBase
{
public:
  using ZoneType = T;
  using EntityType = E;
  using CollectionType = Collection<ZoneType>;

  /// @returns true if the instrument has a global zone
  bool hasGlobalZone() const { return zones_.hasGlobal(); }

  /// @returns the collection's global zone if there is one
  const ZoneType* globalZone() const { return zones_.global(); }

  /// @returns the collection of zones associated with the child class
  const CollectionType& zones() const { return zones_; }

  /// @returns the preset/instrument's entity from the SF2 file
  const EntityType& configuration() const { return configuration_; }

protected:
  WithCollectionBase(size_t zoneCount, const EntityType& configuration) :
  zones_{zoneCount}, configuration_{configuration} {}

  CollectionType zones_;

private:
  const EntityType& configuration_;
};

} // namespace SF2::Render
