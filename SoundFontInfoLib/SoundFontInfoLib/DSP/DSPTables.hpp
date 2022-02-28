// Copyright © 2021 Brad Howes. All rights reserved.

#pragma once

/**
 Namespace for compile-time generated tables. Each table is encapsulated in a `struct` that has three components:
 
 - a `TableSize` definition that states how many entries are in the table (all tables hold `Float` values).
 - a `lookup_` class attribute that declares the lookup table
 - a `value` class method that returns the `Float` value to store at a given table index
 
 All structs also include a class method that performs a lookup for a given value. However, this is not used by the
 table generating infrastructure.
 */
namespace SF2::DSP::Tables {

struct Generator;

/**
 Lookup tables for SF2 pan values, where -500 means only left-channel, and +500 means only right channel. Other values
 give attenuation values for the left and right channels between 0.0 and 1.0. These values come from the sine function
 for a pleasing audio experience when panning.

 NOTE: FluidSynth has a table size of 1002 for some reason. Thus its values are slightly off from what this table
 contains. I don't see a reason for the one extra element.
 */
struct PanLookup {
  inline constexpr static size_t TableSize = 500 + 500 + 1;

  /**
   Obtain the attenuation values for the left and right channels.
   
   @param pan the pan setting
   @param left reference to left channel attenuation storage
   @param right reference to right channel attenuation storage
   */
  static void lookup(Float pan, Float& left, Float& right) {
    int index = std::clamp(int(std::round(pan)), -500, 500);
    left = Float(lookup_[size_t(-index + 500)]);
    right = Float(lookup_[size_t(index + 500)]);
  }

private:
  inline constexpr static Float Scaling = HalfPI / (TableSize - 1);
  
  static double value(size_t index) { return std::sin(index * Scaling); }
  
  static const std::array<double, PanLookup::TableSize> lookup_;
  PanLookup() = delete;
  friend struct Generator;
};

/**
 Estimate std::sin() value using a table of pre-calculated sin values and linear interpolation.
 */
struct SineLookup {
  inline constexpr static size_t TableSize = 4096;
  
  /**
   Obtain sine value.
   
   @param radians the angle in radians to use
   */
  inline static double sine(Float radians) {
    if (radians < 0.0) return -sin(-radians);
    while (radians > TwoPI) radians -= TwoPI;
    if (radians <= HalfPI) return interpolate(radians);
    if (radians <= PI) return interpolate(PI - radians);
    if (radians <= 3 * HalfPI) return -interpolate(radians - PI);
    return -interpolate(TwoPI - radians);
  }
  
private:
  inline constexpr static Float TableScale = (TableSize - 1) / HalfPI;
  inline constexpr static Float Scaling = HalfPI / (TableSize - 1);
  
  inline static double interpolate(Float radians) {
    double phase = clamp(radians, 0.0, HalfPI) * TableScale;
    size_t index = size_t(phase);
    double partial = phase - index;
    double value = lookup_[index] * (1.0f - partial);
    if (partial > 0.0) value += lookup_[index + 1] * partial;
    return value;
  }

  static Float value(size_t index) { return std::sin(index * Scaling); }

  static const std::array<double, TableSize> lookup_;
  SineLookup() = delete;
  friend struct Generator;
};

/**
 Convert cent into frequency multiplier using a table lookup. For instance, to reduce a frequency by -1200 cents means
 to drop 1 octave which is the same as multiplying the source frequency by 0.5. In the other direction an increase of
 1200 cents should result in a multiplier of 2.0 to double the source frequency.
 */
struct CentsFrequencyScalingLookup {
  inline constexpr static int Max = 1200;
  inline constexpr static size_t TableSize = Max * 2 + 1;
  
  /**
   Convert given cents value into a frequency multiplier.
   
   @param value the value to convert
   @returns multiplier for a frequency that will change the frequency by the given cent value
   */
  static double convert(int value) { return lookup_[size_t(std::clamp(value, -Max, Max) + Max)]; }
  
  static double convert(Float value) { return convert(int(std::round(value))); }
  
private:
  inline constexpr static Float Span = Float((TableSize - 1) / 2);
  
  static Float value(size_t index) { return std::exp2((index - Span) / Span); }
  
  static const std::array<double, TableSize> lookup_;
  CentsFrequencyScalingLookup() = delete;
  friend struct Generator;
};

/**
 Convert cents [0-1200) into frequency multiplier. This is used by the centsToFrequency() function to perform a fast
 conversion between cents and frequency.
 */
struct CentsPartialLookup {
  inline constexpr static int MaxCentsValue = 1200;
  inline constexpr static size_t TableSize = MaxCentsValue;

  /**
   Convert a value between 0 and 1200 into a frequency multiplier. See DSP::centsToFrequency for details on how it is
   used.

   @param partial a value between 0 and MaxCentsValue - 1
   @returns frequency multiplier
   */
  static double convert(int partial) { return lookup_[size_t(std::clamp(partial, 0, MaxCentsValue - 1))]; }
  
private:
  static double value(size_t index) { return 6.875 * std::exp2(double(index) / 1200.0); }
  static const std::array<double, TableSize> lookup_;
  CentsPartialLookup() = delete;
  friend struct Generator;
};

/**
 Convert centibels into attenuation via table lookup.
 */
struct AttenuationLookup {
  inline constexpr static size_t TableSize = 1441;
  
  /**
   Convert from integer (generator) value to attenuation.
   
   @param centibels value to convert
   */
  static double convert(int centibels) { return lookup_[size_t(std::clamp<int>(centibels, 0, TableSize - 1))]; }
  
  /**
   Convert from floating-point value to attenuation. Rounds to nearest integer to obtain index.
   
   @param centibels value to convert
   */
  static double convert(Float centibels) { return convert(int(std::round(centibels))); }
  
private:
  static const std::array<double, TableSize> lookup_;
  
  static double value(size_t index) { return centibelsToAttenuation(index); }
  
  AttenuationLookup() = delete;
  friend struct Generator;
};

/**
 Convert centibels into gain value (same as 1.0 / attenuation)
 */
struct GainLookup {
  inline constexpr static size_t TableSize = 1441;
  
  /**
   Convert from integer (generator) value to gain
   
   @param centibels value to convert
   */
  static double convert(int centibels) { return lookup_[size_t(std::clamp<int>(centibels, 0, TableSize - 1))]; }
  
  /**
   Convert from floating-point value to gain. Rounds to nearest integer to obtain index.
   
   @param centibels value to convert
   */
  static double convert(Float centibels) { return convert(int(std::round(centibels))); }
  
private:
  static double value(size_t index) { return 1.0 / centibelsToAttenuation(index); }
  static const std::array<double, TableSize> lookup_;
  GainLookup() = delete;
  friend struct Generator;
};

/**
 Interpolation using a cubic 4th-order polynomial. The coefficients of the polynomial are stored in a lookup table that
 is generated at compile time.
 */
struct Cubic4thOrder {
  
  /// Number of weights (x4) to generate.
  inline constexpr static size_t TableSize = 1024;
  
  using WeightsArray = std::array<std::array<double, 4>, TableSize>;
  
  /**
   Interpolate a value from four values.
   
   @param partial location between the second value and the third. By definition it should always be < 1.0
   @param x0 first value to use
   @param x1 second value to use
   @param x2 third value to use
   @param x3 fourth value to use
   */
  inline static double interpolate(Float partial, Float x0, Float x1, Float x2, Float x3) {
    auto index = size_t(partial * TableSize);
    assert(index < TableSize); // should always be true based on definition of `partial`
    const auto& w{weights_[index]};
    return x0 * w[0] + x1 * w[1] + x2 * w[2] + x3 * w[3];
  }
  
private:
  
  /**
   Array of weights used during interpolation. Initialized at startup.
   */
  static const WeightsArray weights_;
  Cubic4thOrder() = delete;
  friend struct Generator;
};

} // SF2::DSP::Tables namespaces
