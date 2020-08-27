// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "BinaryStream.hpp"
#include "SFGeneratorDefinition.hpp"

namespace SF2 {

/**
 Memory layout of a 'pgen'/'igen' entry. The size of this is defined to be 4. Each instance represents a generator
 configuration.
 */
class SFGenerator {
public:
    static constexpr size_t size = 4;

    explicit SFGenerator(BinaryStream& is) { is.copyInto(this); }

    SFGenIndex index() const { return index_.index(); }
    SFGeneratorAmount value() const { return amount_; }

    SFGeneratorDefinition const& definition() const { return SFGeneratorDefinition::definition(index_); }

    std::string const& name() const { return definition().name(); }

    void dump(const std::string& indent, int index) const;

private:
    SFGeneratorIndex index_;
    SFGeneratorAmount amount_;
};

}
