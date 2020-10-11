// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "../IO/Pos.hpp"
#include "GeneratorDefinition.hpp"

namespace SF2 {
namespace Entity {

/**
 Memory layout of a 'pgen'/'igen' entry. The size of this is defined to be 4. Each instance represents a generator
 configuration.
 */
class Generator {
public:
    static constexpr size_t size = 4;

    explicit Generator(IO::Pos& pos) { pos = pos.readInto(*this); }

    GenIndex index() const { return index_.index(); }
    GeneratorAmount value() const { return amount_; }

    GeneratorDefinition const& definition() const { return GeneratorDefinition::definition(index_); }

    std::string const& name() const { return definition().name(); }

    void dump(const std::string& indent, int index) const;

private:
    GeneratorIndex index_;
    GeneratorAmount amount_;
};

}
}
