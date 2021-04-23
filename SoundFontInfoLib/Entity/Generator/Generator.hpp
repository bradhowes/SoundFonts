// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "Entity/Generator/Definition.hpp"
#include "Entity/Generator/Index.hpp"
#include "IO/Pos.hpp"

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
    Amount amount() const { return amount_; }

    /// @returns meta-data for the generator
    const Definition& definition() const { return Definition::definition(index_.index()); }

    /// @returns the name of the generator
    const std::string& name() const { return definition().name(); }

    /// @returns the configured value of a generator
    int value() const { return definition().valueOf(amount_); }

    void dump(const std::string& indent, int index) const;

private:
    RawIndex index_;
    Amount amount_;
};

} // end namespace Generator
} // end namespace Entity
} // end namespace SF2
