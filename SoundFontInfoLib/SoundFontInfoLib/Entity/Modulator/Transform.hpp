// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <cmath>
#include <iosfwd>

#include "Types.hpp"

namespace SF2::Entity::Modulator {

/**
 Modulator value transform. The spec defines two types:

 - linear: value is used as-is
 - absolute: negative values are made positive before being used

 Currently, all modulators seem to use `linear`.
 */
class Transform {
public:

  enum struct Kind {
    linear = 0,
    absolute = 2
  };

  /**
   Constructor

   @param bits the value that determines the type of transform to apply
   */
  explicit Transform(uint16_t bits) : bits_{bits} {}

  /**
   Default constructor.
   */
  Transform() : Transform(0) {}

  /// @returns the kind of transform to apply
  Kind kind() const { return bits_ == 0 ? Kind::linear : Kind::absolute; }

  /**
   Transform a value.

   @param value the value to transform
   @returns transformed value
   */
  template <typename T>
  T transform(T value) const {
    switch (kind()) {
      case Kind::linear: return value;
      case Kind::absolute: return std::abs(value);
      default: throw "unexpected transform kind";
    }
  }

  friend std::ostream& operator<<(std::ostream& os, const Transform& value);

private:
  const uint16_t bits_;
};

} // end namespace SF2::Entity::Modulator
