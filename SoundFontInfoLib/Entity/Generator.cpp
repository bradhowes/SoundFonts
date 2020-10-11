// Copyright © 2020 Brad Howes. All rights reserved.

#include <iostream>

#include "Generator.hpp"
#include "GeneratorDefinition.hpp"

using namespace SF2::Entity;

struct Dumper {
    GeneratorDefinition const& genDef_;
    GeneratorAmount const& amount_;

    explicit Dumper(GeneratorDefinition const& genDef, GeneratorAmount const& amount)
    : genDef_{genDef}, amount_{amount} {}

    friend std::ostream& operator <<(std::ostream& os, Dumper const& dumper)
    {
        dumper.genDef_.dump(dumper.amount_);
        return os;
    }
};

void
Generator::dump(const std::string& indent, int index) const
{
    std::cout << indent << index << ": " << name() << " setting: " << Dumper(definition(), amount_) << std::endl;
}
