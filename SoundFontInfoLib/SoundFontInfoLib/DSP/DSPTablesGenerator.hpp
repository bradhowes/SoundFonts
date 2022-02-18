// Copyright © 2021 Brad Howes. All rights reserved.

#pragma once

#include <iostream>

#include "DSP/DSP.hpp"
#include "MIDI/ValueTransformer.hpp"

namespace SF2::DSP::Tables {

/**
 Table value generators and initializers. This is only used by the DSPGenerators program which creates the DSP tables
 at compile time for quick loading at runtime.
 */
struct Generator {
  std::ostream& os_;
  
  /**
   Generic table generator. The template type `T` must define a `TableSize` class parameter that gives the size of the
   table to initialize, and it must define a `Value` class method that takes an index value and returns a value to
   put into the table.
   
   @param name the name of the table to initialize
   */
  template <typename T>
  void generate(const std::string& name) {
    os_ << "const std::array<double, " << name << "::TableSize> " << name << "::lookup_ = {\n";
    for (auto index = 0; index < T::TableSize; ++index) os_ << T::value(index) << ",\n";
    os_ << "};\n\n";
  }

  /**
   Generic ValueTransformer table initializer.
   
   @param proc the function that generates a value for a given table index
   @param name the table name to initialize
   @param bipolar if true, initialize a bipolar table; otherwise, a unipolar one (default).
   */
  void generateTransform(std::function<double(int)> proc, const std::string& name, bool bipolar = false) {
    os_ << "const ValueTransformer::TransformArrayType ValueTransformer::" << name;
    if (bipolar) os_ << "Bipolar";
    os_ << "_ = {\n";

    auto func = bipolar ? [=](auto index) { return unipolarToBipolar(proc(index)); } : proc;
    for (auto index = 0; index < MIDI::ValueTransformer::TableSize; ++index) os_ << func(index) << ",\n";
    os_ << "};\n\n";
  }
  
  /**
   Generate the weights used for the cubic 4th-order interpolation calculations
   Based on code found in FluidSynth. Reordered and normalized to better understand coefficients.
   
   Below comment is from FluidSynth source (see
   https://github.com/FluidSynth/fluidsynth/blob/master/src/gentables/gen_rvoice_dsp.c#L25):
   
   Initialize the coefficients for the interpolation. The math comes from a mail, posted by Olli Niemitalo to the
   music-dsp mailing list (I found it in the music-dsp archives http://www.smartelectronix.com/musicdsp/).
   */
  void generateCubic4thOrderWeights() {
    os_ << "const Tables::Cubic4thOrder::WeightsArray Tables::Cubic4thOrder::weights_ = { {\n";
    for (auto index = 0; index < Tables::Cubic4thOrder::TableSize; ++index) {
      auto x = double(index) / double(Tables::Cubic4thOrder::TableSize);
      auto x_05 = 0.5 * x;
      auto x2 = x * x;
      auto x3 = x2 * x;
      auto x3_05 = 0.5 * x3;
      auto x3_15 = 1.5 * x3;
      os_ << "{ ";
      os_ << -x3_05 +       x2 - x_05        << ", ";  // w0
      os_ <<  x3_15 - 2.5 * x2         + 1.0 << ", ";  // w1
      os_ << -x3_15 + 2.0 * x2 + x_05        << ", ";  // w2
      os_ <<  x3_05 - 0.5 * x2               << " },"; // w3
      os_ << "\n";
    }
    os_ << "} };\n\n";
  }
  
  Generator(std::ostream& os);
};

} // SF2::DSP::Tables
