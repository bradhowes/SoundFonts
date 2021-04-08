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
#include "Render/Range.hpp"

namespace SF2 {
namespace Render {

/**
 A zone represents a collection of generator and modulator settings that apply to a range of MIDI key and velocity
 values. There are two types: instrument zones and preset zones. Generator settings for the former specify actual values
 to use, while those in preset zones define adjustments to values set by the instrument.
 */
class Zone
{
public:
    using GeneratorCollection = IO::ChunkItems<Entity::Generator::Generator>::ItemRefCollection;
    using ModulatorCollection = IO::ChunkItems<Entity::Modulator::Modulator>::ItemRefCollection;

    /// A range that always returns true for any MIDI value.
    static Range const all;

    const Range& keyRange() const { return keyRange_; }
    const Range& velocityRange() const { return velocityRange_; }

    const GeneratorCollection& generators() const { return generators_; }
    const ModulatorCollection& modulators() const { return modulators_; }

protected:

    static Range KeyRange(const GeneratorCollection& gens)
    {
        if (gens.size() > 0 && gens[0].get().index() == Entity::Generator::Index::keyRange)
            return Range(gens[0].get().value());
        return all;
    }

    static Range VelocityRange(const GeneratorCollection& gens)
    {
        if (gens.size() > 0 && gens[0].get().index() == Entity::Generator::Index::velocityRange) return Range(gens[0].get().value());
        if (gens.size() > 1 && gens[0].get().index() == Entity::Generator::Index::velocityRange) return Range(gens[1].get().value());
        return all;
    }

    static bool IsGlobal(const GeneratorCollection& gens, Entity::Generator::Index expected, const ModulatorCollection& mods)
    {
        return (gens.empty() && !mods.empty()) || (!gens.empty() && gens.back().get().index() != expected);
    }

    Zone(GeneratorCollection&& gens, ModulatorCollection&& mods, Entity::Generator::Index terminal) :
    generators_{gens},
    modulators_{mods},
    isGlobal_{IsGlobal(gens, terminal, mods)},
    keyRange_{KeyRange(gens)}, velocityRange_{VelocityRange(gens)}
    {}

    void apply(Configuration& cfg) const
    {
        std::for_each(generators_.begin(), generators_.end(), [&](const Entity::Generator::Generator& gen) {
            cfg[gen.index()] = gen.value();
        });
    }

    void refine(Configuration& cfg) const
    {
        std::for_each(generators_.begin(), generators_.end(), [&](const Entity::Generator::Generator& gen) {
            // if (gen.definition().isAdditiveInPreset()) cfg[gen.index()].refine(gen.value().amount());
        });
    }

public:

    bool appliesTo(int key, int velocity) const {
        assert(!isGlobal_);
        return keyRange_.contains(key) && velocityRange_.contains(velocity);
    }

    bool isGlobal() const { return isGlobal_; }

    uint16_t resourceLink() const {
        assert(!isGlobal_);
        return generators_.back().get().value().index();
    }

private:
    GeneratorCollection generators_;
    ModulatorCollection modulators_;

    Range keyRange_;
    Range velocityRange_;
    bool isGlobal_;
};

} // namespace Render
} // namespace SF2
