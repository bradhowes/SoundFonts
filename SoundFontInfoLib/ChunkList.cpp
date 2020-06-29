// Copyright © 2020 Brad Howes. All rights reserved.

#include "Chunk.hpp"
#include "ChunkList.hpp"

using namespace SF2;

ChunkList::const_iterator ChunkList::find(const Tag& tag) const
{
    return find_if(begin(), end(), [&] (const Chunk& value) { return value.tag() == tag; });
}

ChunkList::const_iterator ChunkList::findNext(ChunkList::const_iterator it, const Tag& tag) const
{
    return find_if(++it, end(), [&] (const Chunk& value) { return value.tag() == tag; });
}
