// Copyright © 2020 Brad Howes. All rights reserved.

#include <iostream>

#include "Parser.hpp"
#include "SFGenList.hpp"

using namespace SF2;

const char*
sfGenList::load(const char* pos, size_t available)
{
    if (available < sizeof(sfGenList)) throw FormatError;
    memcpy(&sfGenOper, pos, sizeof(sfGenList));
    pos += sizeof(sfGenList);
    return pos;
}

void
sfGenList::dump(const std::string& indent, int index) const
{
    std::cout << indent << index << ": " << sfGenOper.name()
    << " wAmount: " << genAmount.wAmount()
    << " shAmount: " << genAmount.shAmount()
    << " low: " << genAmount.low()
    << " hi: " << genAmount.high()
    << std::endl;
}
