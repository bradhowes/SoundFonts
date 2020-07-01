// Copyright © 2020 Brad Howes. All rights reserved.

#include <algorithm>
#include <fstream>
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

    explicit PatchInfo(sfPreset const& preset)
    : name(preset.achPresetName), bank(preset.wBank), patch(preset.wPreset) {}
};

struct InternalSoundFontInfo {
    InternalSoundFontInfo(void const* data, size_t size)
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

            // Locate all "patch header" chunks. There actually should only be one.
            auto patchHeader = patchData->find(Tag::phdr);
            if (patchHeader != patchData->end()) {
                auto presetHeader = Preset(*patchHeader);
                patches_.reserve(presetHeader.size());

                // Do not load the last entry (which should always be "EOP")
                std::for_each(presetHeader.begin(), presetHeader.end() - 1,
                              [this](sfPreset const& entry) { patches_.emplace_back(PatchInfo(entry)); });

                // Sort patches in increasing order by bank, patch
                std::sort(patches_.begin(), patches_.end(), [](PatchInfo const& a, PatchInfo const& b) {
                    return a.bank < b.bank || (a.bank == b.bank && a.patch < b.patch);
                });
            }
        }
    }

    void const* data_;
    size_t size_;
    SF2::Chunk top_;
    std::string name_;
    std::vector<PatchInfo> patches_;
};

InternalSoundFontInfo const*
InternalSoundFontParse(void const* data, size_t size)
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

SoundFontInfo SoundFontParse(void const* data, size_t size)
{
    return static_cast<SoundFontInfo>(InternalSoundFontParse(data, size));
}

char const* SoundFontName(SoundFontInfo object)
{
    return static_cast<InternalSoundFontInfo const*>(object)->name_.c_str();
}

size_t SoundFontPatchCount(SoundFontInfo object)
{
    return static_cast<InternalSoundFontInfo const*>(object)->patches_.size();
}

char const* SoundFontPatchName(SoundFontInfo object, size_t index)
{
    return static_cast<InternalSoundFontInfo const*>(object)->patches_[index].name.c_str();
}

int SoundFontPatchBank(SoundFontInfo object, size_t index)
{
    return static_cast<InternalSoundFontInfo const*>(object)->patches_[index].bank;
}

int SoundFontPatchPatch(SoundFontInfo object, size_t index)
{
    return static_cast<InternalSoundFontInfo const*>(object)->patches_[index].patch;
}

struct Redirector {
    std::ofstream* file = nullptr;
    std::streambuf* original = nullptr;

    explicit Redirector(char const* fileName)
    {
        if (fileName != nullptr) {
            file = new std::ofstream(fileName);
            original = std::cout.rdbuf(file->rdbuf());
        }
    }

    ~Redirector() {
        if (original != nullptr) std::cout.rdbuf(original);
        if (file != nullptr) file->close();
    }
};

void SoundFontDump(SoundFontInfo object, char const* fileName)
{
    auto sfi = static_cast<InternalSoundFontInfo const*>(object);
    Redirector redirector(fileName);
    sfi->top_.dump("");
}
