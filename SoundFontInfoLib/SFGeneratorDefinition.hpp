// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <vector>

#include "SFGeneratorIndex.hpp"

namespace SF2 {

class SFGeneratorAmount;

class SFGeneratorDefinition {
public:

    static std::vector<SFGeneratorDefinition> const definitions_;

    enum struct ValueKind {
        unsignedShort = 1,
        signedShort,
        range,
        offset,
        coarseOffset,
        signedCents,
        signedCentsBel,
        unsignedPercent,
        signedPercent,
        signedFreqCents,
        signedTimeCents,
        signedSemitones
    };

    enum Flags : uint16_t {
        unavailableInPreset = 0,
        /// The generator may be present in at the preset level as well as the instrument level
        availableInPreset = 1,
        /// The generator is additive when at the preset level (implies that it is available at the preset level). Otherwise, overrides value.
        additiveInPreset = 3
    };

    static SFGeneratorDefinition const& definition(SFGeneratorIndex index) { return definitions_.at(index.index()); }

    SFGeneratorDefinition(char const* name, ValueKind valueKind, uint16_t flags)
    : name_{name}, valueKind_{valueKind}, flags_{flags} {}

    std::string const& name() const { return name_; }
    ValueKind valueKind() const { return valueKind_; }
    int flags() const { return flags_; }

    bool isAvailableInPreset() const { return (flags_ & availableInPreset) == availableInPreset; }
    bool isAdditiveInPreset() const { return (flags_ & additiveInPreset) == additiveInPreset; }

    void dump(SFGeneratorAmount const& amount) const;

private:
    std::string name_;
    ValueKind valueKind_;
    uint16_t flags_;
};

}
