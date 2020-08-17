// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

namespace SF2 {

class SFGeneratorAmount;

class SFGeneratorDefinition {
public:

    enum ValueKind {
        kValueKindUnsigned = 1,
        kValueKindSigned,
        kValueKindRange,
        kValueKindOffset,
        kValueKindCoarseOffset,
        kValueKindSignedCents,
        kValueKindSignedCentsBel,
        kValueKindUnsignedPercent,
        kValueKindSignedPercent,
        kValueKindSignedFreqCents,
        kValueKindSignedTimeCents,
        kValueKindSignedSemitones
    };

    SFGeneratorDefinition(char const* name, ValueKind kind, bool availableInPreset)
    : name_{name}, kind_{kind}, availableInPreset_{availableInPreset} {}

    std::string const& name() const { return name_; }
    void dump(SFGeneratorAmount const& amount) const;

private:
    std::string name_;
    ValueKind kind_;
    bool availableInPreset_;
};

}
