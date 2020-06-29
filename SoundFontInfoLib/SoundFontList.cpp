// Copyright © 2020 Brad Howes. All rights reserved.

#include <algorithm>
#include <iostream>
#include <vector>
#include <string>

#include "Parser.hpp"
#include "Preset.hpp"
#include "SoundFontList.hpp"

using namespace SF2;

struct PatchInfo {
    std::string name;
    int bank;
    int patch;

    PatchInfo(const sfPreset& preset)
    : name(preset.achPresetName), bank(preset.wBank), patch(preset.wPreset) {}
};

struct InternalSoundFontInfo {
    InternalSoundFontInfo(const void* data, size_t size)
    : data_{data}, size_{size}, top_{SF2::Parser::parse(data, size)}
    {}

    void initialize()
    {
        auto info = top_.find(Tag::info);
        if (info != top_.end()) {
            auto name = info->find(Tag::inam);
            if (name != info->end()) {
                name_ = std::string(name->dataPtr(), name->size());
            }
        }

        // Locate the chunk holding the "patch data"
        auto patchData = top_.find(Tag::pdta);
        if (patchData != top_.end()) {

            // Locate all "patch header" chunks.
            auto patchHeader = patchData->find(Tag::phdr);
            while (patchHeader != patchData->end()) {
                auto presetHeader = Preset(*patchHeader);
                std::for_each(presetHeader.begin(), presetHeader.end(),
                              [this](const sfPreset& entry) { patches_.emplace_back(entry); });

                // Sort patches in increasing order by bank, patch
                std::sort(patches_.begin(), patches_.end(), [](const PatchInfo& a, const PatchInfo& b) {
                    return a.bank < b.bank || (a.bank == b.bank && a.patch < b.patch);
                });
                break;
            }
        }
    }

    const void* data_;
    size_t size_;
    SF2::Chunk top_;
    std::string name_;
    std::vector<PatchInfo> patches_;
};

const InternalSoundFontInfo*
InternalSoundFontParse(const void* data, size_t size)
{
    try {
        auto soundFontInfo = new InternalSoundFontInfo(data, size);
        soundFontInfo->initialize();
        return soundFontInfo;
    }
    catch (enum SF2::Format value) {
        ;
    }

    return nullptr;
}

SoundFontInfo SoundFontParse(const void* data, size_t size)
{
    return static_cast<SoundFontInfo>(InternalSoundFontParse(data, size));
}

const char* SoundFontName(SoundFontInfo object)
{
    return static_cast<const InternalSoundFontInfo*>(object)->name_.c_str();
}

size_t SoundFontPatchCount(SoundFontInfo object)
{
    return static_cast<const InternalSoundFontInfo*>(object)->patches_.size();
}

const char* SoundFontPatchName(SoundFontInfo object, size_t index)
{
    return static_cast<const InternalSoundFontInfo*>(object)->patches_[index].name.c_str();
}

int SoundFontPatchBank(SoundFontInfo object, size_t index)
{
    return static_cast<const InternalSoundFontInfo*>(object)->patches_[index].bank;
}

int SoundFontPatchPatch(SoundFontInfo object, size_t index)
{
    return static_cast<const InternalSoundFontInfo*>(object)->patches_[index].patch;
}

void SoundFontDump(SoundFontInfo object)
{
    auto sfi = static_cast<const InternalSoundFontInfo*>(object);
    sfi->top_.dump("");
}
