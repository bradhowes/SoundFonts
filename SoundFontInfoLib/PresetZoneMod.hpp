// Copyright © 2020 Brad Howes. All rights reserved.

#ifndef PresetZoneMod_hpp
#define PresetZoneMod_hpp

#include <string>

#include "ChunkItems.hpp"
#include "SFModList.hpp"

namespace SF2 {

struct PresetZoneMod : ChunkItems<sfModList, 10>
{
    using Super = ChunkItems<sfModList, 10>;

    PresetZoneMod(const Chunk& chunk) : Super(chunk) {}
};

}

#endif /* PresetZoneMod_hpp */
