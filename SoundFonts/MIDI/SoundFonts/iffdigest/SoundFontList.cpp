//  Copyright © 2019 Brad Howes. All rights reserved.

#include <algorithm>
#include <iostream>
#include <vector>
#include <string>

#include "SoundFontList.hpp"
#include "iffdigest.h"

/**
 Roughly accurate C representation of a 'phdr' entry in a sound font resource. Used to access packed values from a
 resource.
 */
struct sfPresetHeader {
    char achPresetName[20];
    uint16_t wPreset;
    uint16_t wBank;
    uint16_t wPresetBagNdx;
    uint32_t dwLibrary;
    uint32_t dwGenre;
    uint32_t dwMorphology;
};

struct PatchInfo {
    std::string name_;
    int bank_;
    int patch_;

    PatchInfo(const sfPresetHeader* preset)
    : name_(preset->achPresetName), bank_(preset->wBank), patch_(preset->wPreset) {}
};

typedef std::vector<PatchInfo> PatchInfoList;

const PatchInfoList*
InternalSoundFontParse(const void* data, size_t size)
{
    PatchInfoList* patchInfoList = new PatchInfoList();

    try {
        // We only have a `parser` if there the given resource parses correctly.
        auto parser = IFFParser::parse(data, size);

        // Locate the chunk holding the "patch data"
        auto patchData = parser.find("pdta");
        if (patchData != parser.end()) {

            // Locate all "patch header" chunks.
            auto patchHeader = (*patchData).find("phdr");
            while (patchHeader != (*patchData).end()) {

                // Treat as a (packed) array of sfPresetHeader values
                auto pos = (*patchHeader).dataPtr();
                auto end = (*patchHeader).dataPtr() + (*patchHeader).size();
                while (pos < end) {
                    const sfPresetHeader* preset = reinterpret_cast<const sfPresetHeader*>(pos);
                    patchInfoList->push_back(preset);
                    pos += 38; // NOTE: this is *not* the same as sizeof(sfPresetHeader)
                }

                // Sort patches in increasing order by bank, patch
                std::sort(patchInfoList->begin(), patchInfoList->end(),
                          [](const PatchInfo& a, const PatchInfo& b) {
                    return a.bank_ < b.bank_ || (a.bank_ == b.bank_ && a.patch_ < b.patch_); });

                break;
            }
        }
    }
    catch (enum IFFFormat value) {
        ;
    }
    return patchInfoList;
}

PatchInfoListWrapper SoundFontParse(const void* data, size_t size) {
    return static_cast<PatchInfoListWrapper>(InternalSoundFontParse(data, size));
}

size_t PatchInfoListSize(PatchInfoListWrapper object) {
    return static_cast<const PatchInfoList*>(object)->size();
}

const char* PatchInfoName(PatchInfoListWrapper object, size_t index) {
    return (*static_cast<const PatchInfoList*>(object))[index].name_.c_str();
}

int PatchInfoBank(PatchInfoListWrapper object, size_t index) {
    return (*static_cast<const PatchInfoList*>(object))[index].bank_;
}

int PatchInfoPatch(PatchInfoListWrapper object, size_t index) {
    return (*static_cast<const PatchInfoList*>(object))[index].patch_;
}
