// Copyright © 2020 Brad Howes. All rights reserved.

#include <cmath>
#include <iostream>

#include "SFGeneratorAmount.hpp"
#include "SFGeneratorDefinition.hpp"

using namespace SF2;

static float toFreqCents(float value) { return pow(2.0, value / 1200.0) * 8.176; }
static float toTimeCents(float value) { return pow(2.0, value / 1200.0); }

void
SFGeneratorDefinition::dump(const SFGeneratorAmount& amount) const
{
    switch (kind_) {
        case kValueKindUnsigned: std::cout << amount.index(); break;
        case kValueKindSigned: std::cout << amount.amount(); break;
        case kValueKindRange: std::cout << '[' << amount.low() << '-' << amount.high() << ']'; break;
        case kValueKindOffset: std::cout << amount.index() << " bytes"; break;
        case kValueKindCoarseOffset: std::cout << (amount.index() * 32768) << " bytes"; break;
        case kValueKindSignedCents: std::cout << (amount.amount() / 1200.0) << " oct"; break;
        case kValueKindSignedCentsBel: std::cout << (amount.amount() / 10.0) << " dB"; break;
        case kValueKindUnsignedPercent: std::cout << (amount.index() / 10.0) << "%"; break;
        case kValueKindSignedPercent: std::cout << (amount.amount() / 10.0) << "%"; break;
        case kValueKindSignedFreqCents: std::cout << toFreqCents(amount.amount()) << " Hz ("
            << amount.amount() << ')'; break;
        case kValueKindSignedTimeCents: std::cout << toTimeCents(amount.amount()) << " seconds ("
            << amount.amount() << ')'; break;
        case kValueKindSignedSemitones: std::cout << amount.amount() << " notes"; break;
        default: std::cout << amount.amount(); break;
    }
}
