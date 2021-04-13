// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <array>
#include <string>

#include "Entity/Generator/Amount.hpp"
#include "Entity/Generator/Index.hpp"
#include "Render/DSP.hpp"

namespace SF2 {
namespace Entity {
namespace Generator {

/**
 Meta data for SF2 generators. These are attributes associated with a generator but not found in an SF2 file. Rather
 these are attributes called out in the SF2 specification.
 */
class Definition {
public:
    static constexpr size_t NumDefs = static_cast<size_t>(Index::numValues);

    /// The kind of value held by the generator
    enum struct ValueKind {

        // These have isUnsignedValue() == true
        unsignedShort = 1,
        offset,
        coarseOffset,

        // These have isUnsignedValue() == false
        signedShort,
        signedCents,
        signedCentsBel,
        unsignedPercent,
        signedPercent,
        signedFrequencyCents,
        signedTimeCents,
        signedSemitones,

        range
    };

    /**
     Obtain the Definition entry for a given Index value

     @param index value to lookup
     @returns Definition entry
     */
    static const Definition& definition(Index index) { return definitions_.at(static_cast<size_t>(index)); }

    /// @returns name of the definition
    const std::string& name() const { return name_; }

    /// @returns value type of the generator
    ValueKind valueKind() const { return valueKind_; }

    /// @returns true if the generator can be used in a preset zone
    bool isAvailableInPreset() const { return availableInPreset_; }

    bool isUnsignedValue() const { return valueKind_ < ValueKind::signedShort; }

    void dump(const Amount& amount) const;

    /**
     Obtain the value from a generator Amount instance.
     */
    double valueOf(const Amount& amount) const {
        return isUnsignedValue() ? amount.unsignedAmount() : amount.signedAmount();
    }

    double convertedValueOf(const Amount& amount) const {
        switch (valueKind_) {
            case ValueKind::unsignedShort: return amount.unsignedAmount();
            case ValueKind::offset: return amount.unsignedAmount();
            case ValueKind::coarseOffset: return amount.unsignedAmount() * 32768;
            case ValueKind::signedShort: return amount.signedAmount();
            case ValueKind::signedCents: return amount.signedAmount() / 1200.0;
            case ValueKind::signedCentsBel: return amount.signedAmount() / 10.0;
            case ValueKind::unsignedPercent: return amount.signedAmount() / 10.0;
            case ValueKind::signedPercent: return amount.signedAmount() / 10.0;
            case ValueKind::signedFrequencyCents: return DSP::centsToFrequency(amount.signedAmount());
            case ValueKind::signedTimeCents: return DSP::centsToSeconds(amount.signedAmount());
            case ValueKind::signedSemitones: return amount.signedAmount();
            default: return amount.signedAmount();
        }
    }



private:
    static std::array<Definition, NumDefs> const definitions_;

    Definition(const char* name, ValueKind valueKind, bool availableInPreset) :
    name_{name}, valueKind_{valueKind}, availableInPreset_{availableInPreset} {}

    std::string name_;
    ValueKind valueKind_;
    bool availableInPreset_;
};

} // end namespace Generator
} // end namespace Entity
} // end namespace SF2
