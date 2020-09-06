//// Copyright © 2020 Brad Howes. All rights reserved.
//
//#include "Chunk.hpp"
//#include "ChunkList.hpp"
//
//using namespace SF2;
//
//ChunkList::const_iterator ChunkList::find(Tag const& tag) const
//{
//    return find_if(begin(), end(), [&] (Chunk const& value) { return value.tag() == tag; });
//}
//
//ChunkList::const_iterator ChunkList::findNext(ChunkList::const_iterator it, Tag const& tag) const
//{
//    return find_if(++it, end(), [&] (Chunk const& value) { return value.tag() == tag; });
//}
