// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <array>
#include <string>

#include "DSP/DSP.hpp"
#include "Entity/Generator/Amount.hpp"
#include "Entity/Generator/Index.hpp"

namespace SF2 {
namespace Entity {
namespace Generator {

/**
 Meta data for SF2 generators. These are attributes associated with a generator but that are not found in an SF2 file.
 Rather these are attributes called out in the SF2 specification or to make the rendering implementation easier to
 understand.
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

        // Two 8-int bytes
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

    /// @returns true if the generator amount value is unsigned or signed
    bool isUnsignedValue() const { return valueKind_ < ValueKind::signedShort; }

    /**
     Obtain the value from a generator Amount instance. Properly handles unsigned integer values.

     @param amount the container holding the value to extract
     @returns extracted value
     */
    int valueOf(const Amount& amount) const {
        return isUnsignedValue() ? amount.unsignedAmount() : amount.signedAmount();
    }

    /**
     Obtain the value from a generator Amount instance (from an SF2 file) after converting it to its natural or desired
     form.

     @param amount the container holding the value to extract
     @returns the converted value
     */
    double convertedValueOf(const Amount& amount) const {
        switch (valueKind_) {
            case ValueKind::coarseOffset: return valueOf(amount) * 32768;
            case ValueKind::signedCents: return valueOf(amount) / 1200.0;

            case ValueKind::signedCentsBel:
            case ValueKind::unsignedPercent:
            case ValueKind::signedPercent: return valueOf(amount) / 10.0;

            case ValueKind::signedFrequencyCents: return DSP::centsToFrequency(valueOf(amount));
            case ValueKind::signedTimeCents: return DSP::centsToSeconds(valueOf(amount));

            default: return valueOf(amount);
        }
    }

    void dump(const Amount& amount) const;

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
