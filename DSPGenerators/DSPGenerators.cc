// Copyright © 2021 Brad Howes. All rights reserved.
#include <iostream>
#include <iomanip>

#include "DSP.hpp"
#include "DSPGenerators.hpp"
#include "MIDI/ValueTransformer.hpp"

using namespace SF2::DSP;
using namespace SF2::MIDI;

void
Generators::Generate(std::ostream& os) {
    os << std::fixed;
    os << std::setprecision(16); // should be OK for 64-bit doubles
    os << std::showpoint;

    os << "// This file is auto-generated by the DSPGenerators program\n";
    os << "// See the DSPGenerators/DSPGenerators.cc file\n\n";
    os << "#include \"DSP.hpp\"\n";
    os << "#include \"MIDI/ValueTransformer.hpp\"\n\n";
    os << "using namespace SF2::DSP;\n\n";
    os << "using namespace SF2::MIDI;\n\n";

    auto scale = HalfPI / (SineLookup::TableSize - 1);
    os << "const std::array<double, SineLookup::TableSize> SineLookup::lookup_ = {\n";
    for (auto index = 0; index < SineLookup::TableSize; ++index) {
        os << std::sin(scale * index) << ",\n";
    }
    os << "};\n\n";

    os << "const std::array<double, CentsFrequencyLookup::TableSize> CentsFrequencyLookup::lookup_ = {\n";
    auto span = double((CentsFrequencyLookup::TableSize - 1) / 2);
    for (auto index = 0; index < CentsFrequencyLookup::TableSize; ++index) {
        os << std::pow(2.0, (index - span) / span) << ",\n";
    }
    os << "};\n\n";

    os << "const std::array<double, CentsPartialLookup::MaxCentsValue> CentsPartialLookup::lookup_ = {\n";
    for (auto index = 0; index < CentsPartialLookup::TableSize; ++index) {
        os << (6.875 * std::pow(2.0, double(index) / 1200.0)) << ",\n";
    }
    os << "};\n\n";

    os << "const std::array<double, AttenuationLookup::TableSize> AttenuationLookup::lookup_ = {\n";
    for (auto index = 0; index < AttenuationLookup::TableSize; ++index) {
        os << centibelsToNorm(index) << ",\n";
    }
    os << "};\n\n";

    os << "const std::array<double, GainLookup::TableSize> GainLookup::lookup_ = {\n";
    for (auto index = 0; index < GainLookup::TableSize; ++index) {
        os << 1.0 / centibelsToNorm(index) << ",\n";
    }
    os << "};\n\n";

    // --- ValueTransformer tables ---

    // unipolar ranges

    size_t size = ValueTransformer::TableSize;
    size_t last = ValueTransformer::TableSize - 1;
    os << "const ValueTransformer::TransformArrayType ValueTransformer::positiveLinear_ = {\n";
    for (auto index = 0; index < size; ++index) {
        os << double(index) / ValueTransformer::TableSize << ",\n";
    }
    os << "};\n\n";

    os << "const ValueTransformer::TransformArrayType ValueTransformer::negativeLinear_ = {\n";
    for (auto index = 0; index < size; ++index) {
        os << 1.0 - double(index) / ValueTransformer::TableSize << ",\n";
    }
    os << "};\n\n";

    os << "const ValueTransformer::TransformArrayType ValueTransformer::positiveConcave_ = {\n";
    for (auto index = 0; index < size; ++index) {
        os << (index == last ? 1.0 : -40.0 / 96.0 * std::log10((127.0 - index) / 127.0)) << ",\n";
    }
    os << "};\n\n";

    os << "const ValueTransformer::TransformArrayType ValueTransformer::negativeConcave_ = {\n";
    for (auto index = 0; index < size; ++index) {
        os << (index == 0 ? 1.0 : -40.0 / 96.0 * std::log10(index / 127.0)) << ",\n";
    }
    os << "};\n\n";

    os << "const ValueTransformer::TransformArrayType ValueTransformer::positiveConvex_ = {\n";
    for (auto index = 0; index < size; ++index) {
        os << (index == 0 ? 0.0 : 1.0 - -40.0 / 96.0 * std::log10(index / 127.0)) << ",\n";
    }
    os << "};\n\n";

    os << "const ValueTransformer::TransformArrayType ValueTransformer::negativeConvex_ = {\n";
    for (auto index = 0; index < size; ++index) {
        os << (index == last ? 0.0 : 1.0 - -40.0 / 96.0 * std::log10((127.0 - index) / 127.0)) << ",\n";
    }
    os << "};\n\n";

    os << "const ValueTransformer::TransformArrayType ValueTransformer::positiveSwitched_ = {\n";
    for (auto index = 0; index < size; ++index) {
        os << (index < size / 2 ? 0.0 : 1.0) << ",\n";
    }
    os << "};\n\n";

    os << "const ValueTransformer::TransformArrayType ValueTransformer::negativeSwitched_ = {\n";
    for (auto index = 0; index < size; ++index) {
        os << (index < size / 2 ? 1.0 : 0.0) << ",\n";
    }
    os << "};\n\n";

    // bipolar ranges

    os << "const ValueTransformer::TransformArrayType ValueTransformer::positiveLinearBipolar_ = {\n";
    for (auto index = 0; index < size; ++index) {
        os << (2.0 * (double(index) / ValueTransformer::TableSize) - 1.0) << ",\n";
    }
    os << "};\n\n";

    os << "const ValueTransformer::TransformArrayType ValueTransformer::negativeLinearBipolar_ = {\n";
    for (auto index = 0; index < size; ++index) {
        os << (2.0 * (1.0 - double(index) / ValueTransformer::TableSize) - 1.0) << ",\n";
    }
    os << "};\n\n";

    os << "const ValueTransformer::TransformArrayType ValueTransformer::positiveConcaveBipolar_ = {\n";
    for (auto index = 0; index < size; ++index) {
        os << (index == last ? 1.0 : (2.0 * (-40.0 / 96.0 * std::log10((127.0 - index) / 127.0)) - 1.0)) << ",\n";
    }
    os << "};\n\n";

    os << "const ValueTransformer::TransformArrayType ValueTransformer::negativeConcaveBipolar_ = {\n";
    for (auto index = 0; index < size; ++index) {
        os << (index == 0 ? 1.0 : (2.0 * (-40.0 / 96.0 * std::log10(index / 127.0)) - 1.0)) << ",\n";
    }
    os << "};\n\n";

    os << "const ValueTransformer::TransformArrayType ValueTransformer::positiveConvexBipolar_ = {\n";
    for (auto index = 0; index < size; ++index) {
        os << (index == 0 ? -1.0 : (2.0 * (1.0 - -40.0 / 96.0 * std::log10(index / 127.0)) - 1.0)) << ",\n";
    }
    os << "};\n\n";

    os << "const ValueTransformer::TransformArrayType ValueTransformer::negativeConvexBipolar_ = {\n";
    for (auto index = 0; index < size; ++index) {
        os << (index == last ? -1.0 : (2.0 * (1.0 - -40.0 / 96.0 * std::log10((127.0 - index) / 127.0)) - 1.0))
        << ",\n";
    }
    os << "};\n\n";

    os << "const ValueTransformer::TransformArrayType ValueTransformer::positiveSwitchedBipolar_ = {\n";
    for (auto index = 0; index < size; ++index) {
        os << (index < size / 2 ? -1.0 : 1.0) << ",\n";
    }
    os << "};\n\n";

    os << "const ValueTransformer::TransformArrayType ValueTransformer::negativeSwitchedBipolar_ = {\n";
    for (auto index = 0; index < size; ++index) {
        os << (index < size / 2 ? 1.0 : -1.0) << ",\n";
    }
    os << "};\n\n";
}