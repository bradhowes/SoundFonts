// Copyright © 2020 Brad Howes. All rights reserved.

#include <iostream>

#include "Entity/Generator/Amount.hpp"
#include "Entity/Generator/Definition.hpp"
#include "Entity/Generator/Generator.hpp"

using namespace SF2::Entity::Generator;

struct Dumper {
  const Definition& genDef_;
  const Amount& amount_;

  explicit Dumper(const Definition& genDef, const Amount& amount) : genDef_{genDef}, amount_{amount} {}

  friend std::ostream& operator <<(std::ostream& os, const Dumper& dumper)
  {
    dumper.genDef_.dump(dumper.amount_);
    return os;
  }
};

void
Generator::dump(const std::string& indent, size_t index) const
{
  std::cout << indent << '[' << index << "] " << name() << ' ' << Dumper(definition(), amount_) << std::endl;
}
