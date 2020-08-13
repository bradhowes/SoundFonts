// Copyright © 2020 Brad Howes. All rights reserved.

#ifndef PresetZoneMod_hpp
#define PresetZoneMod_hpp

#include <string>

#include "ChunkItems.hpp"
#include "SFModList.hpp"

namespace SF2 {

struct PresetZoneMod : ChunkItems<sfModList>
{
    using Super = ChunkItems<sfModList>;

    PresetZoneMod(Chunk const& chunk) : Super(chunk) {}
};

}

#endif /* PresetZoneMod_hpp */
