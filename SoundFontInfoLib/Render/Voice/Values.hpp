// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <cstdlib>

#include "Entity/Generator/Amount.hpp"
#include "Render/DSP.hpp"

namespace SF2 {
namespace Render {
namespace Voice {
namespace Value {

class Offset {
public:
    explicit Offset(int value) : value_{value} {}
    size_t value() const { return value_; }
    Offset operator +(const Offset& rhs) const { return Offset(value_ + rhs.value_); }
    Offset operator -(const Offset& rhs) const { return Offset(value_ - rhs.value_); }
protected:
    int value_;
};

class CoarseOffset : public Offset {
public:
    explicit CoarseOffset(int value) : Offset(value * 65536) {}
};

class Percentage {
public:
    explicit Percentage(int value) : value_{value / 1000.0} {}
    double value() const { return value_; }
    operator double() const { return value_; }
private:
    double value_;
};

class TimeCents {
public:
    explicit TimeCents(int value) : value_(value) {}
    int value() const { return value_; }
    TimeCents operator +(const TimeCents& rhs) const { return TimeCents(value_ + rhs.value_); }
    TimeCents operator -(const TimeCents& rhs) const { return TimeCents(value_ - rhs.value_); }
    double asSeconds() const { return DSP::centsToSeconds(value_); }
private:
    int value_;
};

class FrequencyCents {
public:
    explicit FrequencyCents(int value) : value_(value) {}
    double value() const { return value_; }
    FrequencyCents operator +(const FrequencyCents& rhs) const { return FrequencyCents(value_ + rhs.value_); }
    FrequencyCents operator -(const FrequencyCents& rhs) const { return FrequencyCents(value_ - rhs.value_); }
    double asFrequency() const { return DSP::centsToFrequency(value_); }
private:
    double value_;
};

} // end namespace Value
} // end namespace Generator
} // end namespace Entity
} // end namespace SF2
