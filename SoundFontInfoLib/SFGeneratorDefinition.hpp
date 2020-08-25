// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <array>

#include "SFGeneratorIndex.hpp"

namespace SF2 {

class SFGeneratorAmount;

class SFGeneratorDefinition {
public:

    static constexpr size_t NumDefinitions = 59;
    static std::array<SFGeneratorDefinition, NumDefinitions> const definitions_;

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

    static auto definition(SFGeneratorIndex index) -> auto { return definitions_.at(index.index()); }

    SFGeneratorDefinition(char const* name, ValueKind valueKind, uint16_t flags)
    : name_{name}, valueKind_{valueKind}, flags_{flags} {}

    auto name() const -> auto { return name_; }
    auto valueKind() const -> auto { return valueKind_; }
    auto flags() const -> auto { return flags_; }

    auto isAvailableInPreset() const -> auto { return (flags_ & availableInPreset) == availableInPreset; }
    auto isAdditiveInPreset() const -> auto { return (flags_ & additiveInPreset) == additiveInPreset; }

    void dump(SFGeneratorAmount const& amount) const;

private:
    std::string name_;
    ValueKind valueKind_;
    uint16_t flags_;
};

}
