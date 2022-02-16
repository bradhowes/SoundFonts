// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <cstdlib>

namespace SF2::Entity::Generator {

/**
 Holds the amount to apply to a generator. Note that this is an immutable value that comes straight from an SF2 file.
 It exists as a C union of three value types: unsigned 16-bit int, signed 16-bit int, and pair of 2 unsigned 8-bit
 values used for MIDI key/velocity ranges. As such, it is important to pull out the right value with the right
 method. The associated `Definition` metadata class has methods that can be used to do this correctly and safely.
 */
class Amount {
public:
  static constexpr size_t size = 2;
  
  /**
   Constructor with specific value. Only used for testing. All values for generators should come from SF2 file.
   
   @param raw the value to hold
   */
  explicit Amount(uint16_t raw) : raw_{raw} { assert(sizeof(*this) == size); }
  
  /**
   Default constructor. Sets held value to 0.
   */
  Amount() : Amount(0) {}
  
  /// @returns unsigned integer value
  uint16_t unsignedAmount() const { return raw_.wAmount; }
  
  /// @returns signed integer value
  int16_t signedAmount() const { return raw_.shAmount; }
  
  /// @returns low value of a range (0-255)
  int low() const { return int(raw_.ranges[0]); }

  /// @returns high value of a range (0-255)
  int high() const { return int(raw_.ranges[1]); }
  
private:
  
  union {
    uint16_t wAmount;
    int16_t shAmount;
    uint8_t ranges[2];
  } raw_{0};
};

} // end namespace SF2::Entity::Generator
