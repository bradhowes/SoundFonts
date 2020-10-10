// Copyright © 2020 Brad Howes. All rights reserved.

#include <iostream>

#include "SFGenerator.hpp"
#include "SFGeneratorDefinition.hpp"

using namespace SF2;

struct Dumper {
    SFGeneratorDefinition const& genDef_;
    SFGeneratorAmount const& amount_;

    explicit Dumper(SFGeneratorDefinition const& genDef, SFGeneratorAmount const& amount)
    : genDef_{genDef}, amount_{amount} {}

    friend std::ostream& operator <<(std::ostream& os, Dumper const& dumper)
    {
        dumper.genDef_.dump(dumper.amount_);
        return os;
    }
};

void
SFGenerator::dump(const std::string& indent, int index) const
{
    std::cout << indent << index << ": " << name() << " setting: " << Dumper(definition(), amount_) << std::endl;
}
