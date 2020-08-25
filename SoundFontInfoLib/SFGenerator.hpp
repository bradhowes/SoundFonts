// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "BinaryStream.hpp"
#include "SFGeneratorAmount.hpp"
#include "SFGeneratorDefinition.hpp"
#include "SFGeneratorIndex.hpp"

namespace SF2 {

/**
 Memory layout of a 'pgen'/'igen' entry. The size of this is defined to be 4. Each instance represents a generator
 configuration for a specific SFGenerator.
 */
class SFGenerator {
public:
    static constexpr size_t size = 4;

    explicit SFGenerator(BinaryStream& is) { is.copyInto(this); }
    
    auto definition() const -> auto { return SFGeneratorDefinition::definitions_[index_.index()]; }
    auto name() const -> auto { return definition().name(); }

    struct Dumper {
        SFGeneratorDefinition const& genDef_;
        SFGeneratorAmount const& amount_;

        explicit Dumper(SFGeneratorDefinition const& genDef, SFGeneratorAmount const& amount)
        : genDef_{genDef}, amount_{amount} {}

        friend auto operator <<(std::ostream& os, Dumper const& dumper) -> std::ostream&
        {
            dumper.genDef_.dump(dumper.amount_);
            return os;
        }
    };

    auto dump(SFGeneratorAmount const& amount) const -> auto { return Dumper(definition(), amount); }

    void dump(const std::string& indent, int index) const
    {
        std::cout << indent << index << ": " << name() << " setting: " << dump(amount_)
        << std::endl;
    }

private:
    SFGeneratorIndex index_;
    SFGeneratorAmount amount_;
};

}
