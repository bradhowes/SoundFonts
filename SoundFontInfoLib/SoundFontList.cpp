// Copyright © 2019 Brad Howes. All rights reserved.

#include <algorithm>
#include <iostream>
#include <vector>
#include <string>

#include "SoundFontList.hpp"
#include "SF2.h"

/**
 Roughly accurate C representation of a 'phdr' entry in a sound font resource. Used to access packed values from a
 resource.
 */
struct sfPresetHeader {
    char achPresetName[20];
    uint16_t wPreset;
    uint16_t wBank;
    uint16_t wPresetBagNdx;

    // Due to alignment padding, the following cannot be represented as 32-bit values. Must combine parts instead.
    uint16_t dwLibrary_1;
    uint16_t dwLibrary_2;
    uint16_t dwGenre_1;
    uint16_t dwGenre_2;
    uint16_t dwMorphology_1;
    uint16_t dwMorphology_2;
};

struct PatchInfo {
    std::string name;
    int bank;
    int patch;

    PatchInfo(const sfPresetHeader* preset) : name(preset->achPresetName), bank(preset->wBank), patch(preset->wPreset) {}
};

struct InternalSoundFontInfo {
    std::string name;
    std::vector<PatchInfo> patches;
};

const InternalSoundFontInfo*
InternalSoundFontParse(const void* data, size_t size)
{
    static_assert(sizeof(sfPresetHeader) == 38, "sfPresetHeader size is not 38");

    InternalSoundFontInfo* soundFontInfo = new InternalSoundFontInfo();
    soundFontInfo->name = "";

    try {
        // We only have a `parser` if there the given resource parses correctly.
        auto parser = SF2::Parser::parse(data, size);
        auto info = parser.find(SF2::Tag::info);
        if (info != parser.end()) {
            auto name = info->find(SF2::Tag::inam);
            if (name != info->end()) {
                soundFontInfo->name = std::string(name->dataPtr(), name->size());
            }
        }

        // Locate the chunk holding the "patch data"
        auto patchData = parser.find(SF2::Tag::pdta);
        if (patchData != parser.end()) {

            // Locate all "patch header" chunks.
            auto patchHeader = patchData->find(SF2::Tag::phdr);
            while (patchHeader != patchData->end()) {

                // Treat as a (packed) array of sfPresetHeader values
                auto pos = patchHeader->dataPtr();
                auto end = patchHeader->dataPtr() + (*patchHeader).size();
                while (pos < end) {
                    const sfPresetHeader* preset = reinterpret_cast<const sfPresetHeader*>(pos);
                    soundFontInfo->patches.push_back(preset);
                    pos += sizeof(sfPresetHeader);
                }

                // Sort patches in increasing order by bank, patch
                std::sort(soundFontInfo->patches.begin(), soundFontInfo->patches.end(),
                          [](const PatchInfo& a, const PatchInfo& b) {
                    return a.bank < b.bank || (a.bank == b.bank && a.patch < b.patch); });

                break;
            }
        }
    }
    catch (enum SF2::Format value) {
        ;
    }
    return soundFontInfo;
}

SoundFontInfo SoundFontParse(const void* data, size_t size) {
    return static_cast<SoundFontInfo>(InternalSoundFontParse(data, size));
}

const char* SoundFontName(SoundFontInfo object) {
    return static_cast<const InternalSoundFontInfo*>(object)->name.c_str();
}

size_t SoundFontPatchCount(SoundFontInfo object) {
    return static_cast<const InternalSoundFontInfo*>(object)->patches.size();
}

const char* SoundFontPatchName(SoundFontInfo object, size_t index) {
    return static_cast<const InternalSoundFontInfo*>(object)->patches[index].name.c_str();
}

int SoundFontPatchBank(SoundFontInfo object, size_t index) {
    return static_cast<const InternalSoundFontInfo*>(object)->patches[index].bank;
}

int SoundFontPatchPatch(SoundFontInfo object, size_t index) {
    return static_cast<const InternalSoundFontInfo*>(object)->patches[index].patch;
}
