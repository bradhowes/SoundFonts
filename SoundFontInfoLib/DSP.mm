// Copyright © 2021 Brad Howes. All rights reserved.

#include "DSP.hpp"

using namespace SF2::DSP;

// Initialize table. In Xcode 12, this generates a TEXT segment with values that are loaded at runtime and the code is
// not executed.
const std::array<double, PanLookup::TableSize> PanLookup::lookup_ = [] {
    auto init = decltype(PanLookup::lookup_){};
    auto scale = HalfPI / (TableSize - 1);
    for (auto index = 0; index < init.size(); ++index) {
        init[index] = parabolicSine(scale * index);
    }
    return init;
}();

//// Due to reliance on std::sin() this table will be built at initialization time.
//const std::array<double, SineLookup::TableSize> SineLookup::lookup_ = [] {
//    auto init = decltype(SineLookup::lookup_){};
//    auto scale = HalfPI / (init.size() - 1);
//    for (auto index = 0; index < init.size(); ++index) {
//        init[index] = std::sin(scale * index);
//    }
//    return init;
//}();
//
//
//// Due to reliance on std::pow() this table will be built at initialization time.
//const std::array<double, CentsFrequencyLookup::MaxCentsValue * 2 + 1> CentsFrequencyLookup::lookup_ = [] {
//    auto init = decltype(lookup_){};
//    auto span = double((init.size() - 1) / 2);
//    for (auto index = 0; index < init.size(); ++index) {
//        init[index] = std::pow(2.0, (index - span) / span);
//    }
//    return init;
//}();
//
//// Due to reliance on std::pow() this table will be built at initialization time.
//const std::array<double, CentsPartialLookup::MaxCentsValue> CentsPartialLookup::lookup_ = [] {
//    auto init = decltype(lookup_){};
//    for (auto index = 0; index < init.size(); ++index) {
//        init[index] = 6.875 * std::pow(2.0, double(index) / 1200.0);
//    }
//    return init;
//}();
//
//// Due to reliance on std::pow() this table will be built at initialization time.
//const std::array<double, AttenuationLookup::TableSize> AttenuationLookup::lookup_ = [] {
//    auto init = decltype(lookup_){};
//    for (auto index = 0; index < init.size(); ++index) {
//        init[index] = centibelsToNorm(index);
//    }
//    return init;
//}();
//
//// Due to reliance on std::pow() (via AttenuationLookup) this table will be built at initialization time.
//const std::array<double, GainLookup::TableSize> GainLookup::lookup_ = [] {
//    auto init = decltype(lookup_){};
//    for (auto index = 0; index < init.size(); ++index) {
//        init[index] = 1.0 / AttenuationLookup::convert(index);
//    }
//    return init;
//}();
//
// Initialize weights table. In Xcode 12, this generates a TEXT segment with values that are loaded at runtime and the
// code is not executed.
const Interpolation::Cubic4thOrder::WeightsArray Interpolation::Cubic4thOrder::weights_ = []() {

    // Comment from FluidSynth - see https://github.com/FluidSynth/fluidsynth/blob/master/src/gentables/gen_rvoice_dsp.c
    // Initialize the coefficients for the interpolation. The math comes from a mail, posted by Olli Niemitalo to the
    // music-dsp mailing list (I found it in the music-dsp archives http://www.smartelectronix.com/musicdsp/).
    //
    // Reordered and normalized to better understand coefficients.
    auto init = decltype(weights_){};
    for (int index = 0; index < weightsCount; ++index) {
        auto x = double(index) / double(weightsCount);
        auto x_05 = 0.5 * x;
        auto x2 = x * x;
        auto x3 = x2 * x;
        auto x3_05 = 0.5 * x3;
        auto x3_15 = 1.5 * x3;
        init[index][0] = -x3_05 +       x2 - x_05;
        init[index][1] =  x3_15 - 2.5 * x2         + 1.0;
        init[index][2] = -x3_15 + 2.0 * x2 + x_05;
        init[index][3] =  x3_05 - 0.5 * x2;
    }

    return init;
}();
