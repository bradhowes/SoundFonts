// Copyright © 2020 Brad Howes. All rights reserved.

#ifndef SFGenerator_hpp
#define SFGenerator_hpp

#include <algorithm>
#include <cstdlib>
#include <limits>
#include <vector>

#include "SFGenTypeAmount.hpp"

namespace SF2 {

class GenDef {
public:
    static float fromUnsigned(SFGenTypeAmount amount) { return float(amount.wAmount()); }
    static float fromSigned(SFGenTypeAmount amount) { return float(amount.shAmount()); }
    static float fromLow(SFGenTypeAmount amount) { return float(amount.low()); }
    static float fromHigh(SFGenTypeAmount amount) { return float(amount.high()); }

    template <typename T>
    GenDef(char const* name, T const& def)
    : name_(name),
    minValue_(def.min()),
    maxValue_(def.max()),
    initialValue_(def.initial()),
    getter_{def.getter()}
    {}

    GenDef(char const* name, float minValue, float maxValue, float initialValue, float (*getter)(SFGenTypeAmount))
    : name_{name}, minValue_{minValue}, maxValue_{maxValue}, initialValue_{initialValue}, getter_{getter} {}

    char const* name() const { return name_; }
    float minValue() const { return minValue_; }
    float maxValue() const { return maxValue_; }
    float initialValue() const { return initialValue_; }
    float clamp(float value) const { return std::max(std::min(value, maxValue_), minValue_); }

private:
    char const* name_;
    float minValue_;
    float maxValue_;
    float initialValue_;
    std::function<float (SFGenTypeAmount)> getter_;
};

struct SFGenerator {
    static std::vector<GenDef> const defs;

    SFGenerator() : bits_(0) {}
    SFGenerator(uint16_t bits) : bits_{bits} {}

    uint16_t value() const { return bits_; }

    GenDef const& def() const { return defs[bits_]; }
    char const* name() const { return defs[bits_].name(); }

private:
    const uint16_t bits_;
};

}

#endif /* SFGenerator_hpp */
