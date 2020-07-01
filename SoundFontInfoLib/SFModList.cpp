// Copyright © 2020 Brad Howes. All rights reserved.

#include "Parser.hpp"
#include "SFModList.hpp"

using namespace SF2;

char const*
sfModList::load(char const* pos, size_t available)
{
    if (sizeof(sfModList) != size || available < size) throw FormatError;
    memcpy(this, pos, size);
    pos += size;
    return pos;
}

void
sfModList::dump(const std::string& indent, int index) const
{
    std::cout << indent << index
    << ": src: " << sfModSrcOper
    << " dest: " << sfModDestOper.name()
    << " amount: " << modAmount
    << " op: " << sfModAmtSrcOper
    << " xform: " << sfModTransOper.bits_
    << std::endl;
}
