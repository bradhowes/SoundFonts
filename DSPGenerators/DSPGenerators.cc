// Copyright © 2021 Brad Howes. All rights reserved.
#include <iostream>
#include <iomanip>

#include "DSP.hpp"
#include "DSPGenerators.hpp"

using namespace SF2::DSP;

void
Generators::Generate(std::ostream& os) {
    os << std::fixed;
    os << std::setprecision(16); // should be OK for 64-bit doubles
    os << std::showpoint;

    os << "#include \"Render/DSP.hpp\"\n\n";
    os << "using namespace SF2::DSP;\n\n";

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
}

//// Due to reliance on std::pow() this table will be built at initialization time.
//const std::array<double, CentsFrequencyLookup::MaxCentsValue * 2 + 1> CentsFrequencyLookup::lookup_ = [] {
//    auto init = decltype(lookup_){};
//    auto span = double((init.size() - 1) / 2);
//    for (auto index = 0; index < init.size(); ++index) {
//        init[index] = std::pow(2.0, (index - span) / span);
//    }
//    return init;
//}();
