// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <array>
#include <cstdlib>
#include <iosfwd>
#include <string>

namespace SF2::Entity::Modulator {

/**
 The source of an SF2 modulator. There are two types:
 
 - general controller
 - MIDI continuous controller (CC)
 
 The type is defined by the CC flag (bit 7). The general type points to various common MIDI values as a source of
 modulation, while the CC type allows for a broader collection of controllers.
 */
class Source {
public:
  
  /// Valid sources for a general controller
  enum struct GeneralIndex : uint16_t {
    none = 0,
    noteOnVelocity = 2,
    noteOnKeyValue = 3,
    polyPressure = 10,
    channelPressure = 13,
    pitchWheel = 14,
    pitchWheelSensitivity = 16,
    link = 127
  };
  
  /// Transformations applied to values that come from a source
  enum struct ContinuityType : uint16_t {
    linear = 0,
    concave,
    convex,
    switched
  };
  
  /**
   Constructor
   
   @param bits value that defines a source
   */
  explicit Source(uint16_t bits) : bits_{bits} {}
  
  Source() = default;
  
  /// @returns true if the source is valid
  bool isValid() const {
    if (rawType() > static_cast<uint16_t>(ContinuityType::switched)) return false;
    auto idx = rawIndex();
    if (isContinuousController()) {
      return !(idx == 0 || idx == 6 || (idx >=32 && idx <= 63) || idx == 98 || idx == 101 ||
               (idx >= 120 && idx <= 127));
    }
    else {
      return idx == 0 || idx == 2 || idx == 3 || idx == 10 || idx == 13 || idx == 14 || idx == 16 || idx == 127;
    }
  }
  
  /// @returns true if the source is a continuous controller (CC)
  bool isContinuousController() const { return (bits_ & (1 << 7)) ? true : false; }
  
  /// @returns true if the source is a general controller
  bool isGeneralController() const { return !isContinuousController(); }
  
  /// @returns true if the source acts in a unipolar manner
  bool isUnipolar() const { return polarity() == 0; }
  
  /// @returns true if the source acts in a bipolar manner
  bool isBipolar() const { return !isUnipolar(); }
  
  /// @returns true if the source values go from small to large as the controller goes from min to max
  bool isMinToMax() const { return direction() == 0; }
  
  /// @returns true if the source values go from large to small as the controller goes from min to max
  bool isMaxToMin() const { return !isMinToMax(); }
  
  /// @returns true if this modulator relies on another for a source value
  bool isLinked() const {
    return isValid() && isGeneralController() && generalIndex() == GeneralIndex::link;
  }
  
  /// @returns the index of the general controller (raises exception if not configured to be a general controller)
  GeneralIndex generalIndex() const {
    assert(isValid() && isGeneralController());
    return GeneralIndex(rawIndex());
  }
  
  /// @returns true if this source is not connected to anything (or it is invalid)
  bool isNone() const { return !isValid() || (isGeneralController() && generalIndex() == GeneralIndex::none); }
  
  /// @returns the index of the continuous controller (raises exception if not configured to be a continuous
  /// controller)
  int continuousIndex() const {
    assert(isValid() && isContinuousController());
    return rawIndex();
  }
  
  /// @returns the continuity type for the controller values
  ContinuityType type() const {
    assert(isValid());
    return ContinuityType(rawType());
  }
  
  /// @returns the name of the continuity type
  std::string continuityTypeName() const { return isValid() ? std::string(typeNames[rawType()]) : "N/A"; }
  
  std::string description() const;
  
  friend std::ostream& operator<<(std::ostream& os, const Source& mod);
  
  bool operator ==(const Source& rhs) const { return bits_ == rhs.bits_; }
  bool operator !=(const Source& rhs) const { return bits_ != rhs.bits_; }
  
private:
  static constexpr char const* typeNames[] = { "linear", "concave", "convex", "switched" };
  
  uint16_t rawIndex() const { return bits_ & 0x7F; }
  uint16_t rawType() const { return bits_ >> 10; }
  uint16_t polarity() const { return bits_ & (1 << 9); }
  uint16_t direction() const { return bits_ & (1 << 8); }
  
  uint16_t bits_;
};

} // end namespace SF2::Entity::Modulator
