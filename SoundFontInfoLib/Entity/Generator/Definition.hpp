// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <array>

#include "Entity/Generator/Amount.hpp"
#include "Entity/Generator/Index.hpp"

namespace SF2 {
namespace Entity {
namespace Generator {

/**
 Meta data of an SF2 generator. These are attributes associated with a generator but not found in an SF2 file. Rather
 these are attributes called out in the SF2 specification.
 */
class Definition {
public:
    static constexpr size_t NumDefs = static_cast<size_t>(Index::numValues);

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
        /// The generator may be present at the instrument level only
        unavailableInPreset = 0,
        /// The generator may be present in at the preset level as well as the instrument level
        availableInPreset = 1,
        /// The generator is additive when at the preset level (implies that it is available at the preset level). Otherwise, overrides value.
        additiveInPreset = 3
    };

    static const Definition& definition(Index index) { return definitions_.at(static_cast<uint16_t>(index)); }

    const std::string& name() const { return name_; }
    ValueKind valueKind() const { return valueKind_; }
    uint16_t flags() const { return flags_; }

    bool isAvailableInPreset() const { return (flags_ & availableInPreset) == availableInPreset; }
    bool isAdditiveInPreset() const { return (flags_ & additiveInPreset) == additiveInPreset; }

    void dump(const Amount& amount) const;

private:
    static std::array<Definition, NumDefs> const definitions_;

    Definition(const char* name, ValueKind valueKind, uint16_t flags) : name_{name}, valueKind_{valueKind}, flags_{flags} {}

    std::string name_;
    ValueKind valueKind_;
    int16_t default_;
    uint16_t flags_;
};

}
}
}
