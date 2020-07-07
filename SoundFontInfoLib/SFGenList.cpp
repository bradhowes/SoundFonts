// Copyright © 2020 Brad Howes. All rights reserved.

#include <iostream>

#include "Parser.hpp"
#include "SFGenList.hpp"

using namespace SF2;

char const*
sfGenList::load(char const* pos, size_t available)
{
    if (sizeof(sfGenList) != size || available < size) throw FormatError;
    memcpy(this, pos, size);
    pos += size;
    return pos;
}

void
sfGenList::dump(const std::string& indent, int index) const
{
    std::cout << indent << index << ": " << sfGenOper.name() << " setting: " << sfGenOper.dump(genAmount) << std::endl;
}
