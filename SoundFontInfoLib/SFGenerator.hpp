// Copyright © 2020 Brad Howes. All rights reserved.

#ifndef SFGenerator_hpp
#define SFGenerator_hpp

#include <iosfwd>
#include <vector>

namespace SF2 {

class SFGenTypeAmount;

class GenDef {
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

    GenDef(char const* name, ValueKind kind)
    : name_{name}, kind_{kind} {}

    char const* name() const { return name_; }
    void dump(SFGenTypeAmount const& amount) const;

private:
    char const* name_;
    ValueKind kind_;
};

struct SFGenerator {
    static std::vector<GenDef> const defs;

    SFGenerator() : bits_(0) {}
    SFGenerator(uint16_t bits) : bits_{bits} {}

    uint16_t value() const { return bits_; }

    GenDef const& def() const { return defs[bits_]; }
    char const* name() const { return defs[bits_].name(); }

    struct Dumper {
        GenDef const& genDef_;
        SFGenTypeAmount const& amount_;
        explicit Dumper(GenDef const& genDef, SFGenTypeAmount const& amount) : genDef_{genDef}, amount_{amount} {}
        friend std::ostream& operator <<(std::ostream& os, Dumper const& dumper)
        {
            dumper.genDef_.dump(dumper.amount_);
            return os;
        }
    };

    Dumper dump(SFGenTypeAmount const& amount) const { return Dumper(defs[bits_], amount); }

private:
    const uint16_t bits_;
};

}

#endif /* SFGenerator_hpp */
