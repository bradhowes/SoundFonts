// Copyright © 2020 Brad Howes. All rights reserved.

#ifndef PresetZoneGen_hpp
#define PresetZoneGen_hpp

#include "ChunkItems.hpp"
#include "SFGenList.hpp"

namespace SF2 {

struct PresetZoneGen : ChunkItems<sfGenList>
{
    using Super = ChunkItems<sfGenList>;

    PresetZoneGen(Chunk const& chunk) : Super(chunk) {}
};

}

#endif /* PresetZoneGen_hpp */
