// Copyright © 2020 Brad Howes. All rights reserved.

#include "Parser.hpp"
#include "SFModList.hpp"

using namespace SF2;

const char*
sfModList::load(const char* pos, size_t available)
{
    if (available < sizeof(*this)) throw FormatError;
    memcpy(this, pos, sizeof(*this));
    pos += sizeof(*this);
    return pos;
}

void
sfModList::dump(const std::string& indent, int index) const
{
    std::cout << indent << index
    << ": src: " << sfModSrcOper
    << " dest: " << sfModDestOper.name()
    << " amount: " << modAmount
    << " amountOp: " << sfModAmtSrcOper
    << " xform: " << sfModTransOper.bits_
    << std::endl;
}
