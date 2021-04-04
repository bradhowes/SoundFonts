// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "IO/Pos.hpp"
#include "Entity/Generator/Definition.hpp"
#include "Entity/Generator/Index.hpp"

namespace SF2 {
namespace Entity {
namespace Generator {

/**
 Memory layout of a 'pgen'/'igen' entry. The size of this is defined to be 4. Each instance represents a generator
 configuration.
 */
class Generator {
public:
    static constexpr size_t size = 4;

    /**
     Constructor from file.

     @param pos location in file to read
     */
    explicit Generator(IO::Pos& pos) { assert(sizeof(*this) == size); pos = pos.readInto(*this); }

    /// @returns index of the generator as an enumerated type
    Index index() const { return index_.index(); }

    /// @returns value configured for the generator
    Amount value() const { return amount_; }

    const Definition& definition() const { return Definition::definition(index_.index()); }

    const std::string& name() const { return definition().name(); }

    void dump(const std::string& indent, int index) const;

private:
    RawIndex index_;
    Amount amount_;
};

}
}
}
