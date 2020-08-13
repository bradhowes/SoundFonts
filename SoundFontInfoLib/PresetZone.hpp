//
//  PresetZone.hpp
//  SoundFontInfoLib
//
//  Created by Brad Howes on 6/15/20.
//  Copyright © 2020 Brad Howes. All rights reserved.
//

#ifndef PresetZone_hpp
#define PresetZone_hpp

#include <string>

#include "ChunkItems.hpp"

namespace SF2 {

/**
 Memory layout of a 'pbag' entry in a sound font resource. Used to access packed values from a
 resource. The size of this must be 4.
 */
struct sfPresetBag {
    constexpr static size_t size = 4;

    uint16_t wGenNdx;
    uint16_t wModNdx;

    char const* load(char const* pos, size_t available);
    void dump(const std::string& indent, int index) const;
};

struct PresetZone : ChunkItems<sfPresetBag>
{
    using Super = ChunkItems<sfPresetBag>;

    PresetZone(Chunk const& chunk) : Super(chunk) {}
};

}

#endif /* PresetZone_hpp */
