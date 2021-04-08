// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "Entity/Bag.hpp"
#include "IO/File.hpp"
#include "Render/Configuration.hpp"
#include "Render/InstrumentCollection.hpp"
#include "Render/Zone.hpp"

namespace SF2 {
namespace Render {

class PresetZone : public Render::Zone {
public:
    PresetZone(const IO::File& file, const Render::InstrumentCollection& instruments, const Entity::Bag& bag);

    /// Preset values only refine those from instrument
    void refine(Render::Configuration& configuration) const { Zone::refine(configuration); }

    const Render::Instrument& instrument() const { assert(instrument_ != nullptr); return *instrument_; }

private:
    Render::Instrument const* instrument_;
};

} // namespace Render
} // namespace SF2
