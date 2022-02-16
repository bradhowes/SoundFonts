// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <cassert>
#include <string>
#include <array>

namespace SF2::MIDI {

/**
 A MIDI note representation. MIDI note values range from 0 to 255, and so does this.
 */
class Note {
public:
  inline constexpr static int Min = 0;
  inline constexpr static int Max = 127;

  /**
   Construct new note.

   @param value the MIDI value to represent
   */
  explicit Note(int value) : value_{value}, note_{size_t(value % 12)} {
    assert(value >= 0 && value <= 127);
  }

  /// @returns the octave that the note resides in
  int octave() const { return value_ / 12 - 1; }

  /// @returns true if the note is accented (sharp / flat)
  bool accented() const { return (note_ < 5 && (note_ & 1) == 1) || (note_ > 5 && (note_ & 1) == 0); }

  /// @returns textual representation of the note (shows a sharp for accented notes)
  std::string label() const { return labels_[note_] + std::to_string(octave()) + (accented() ? sharpTag_ : ""); }

  int value() const { return value_; }

  bool operator ==(const Note& rhs) const { return value_ == rhs.value_; }
  bool operator !=(const Note& rhs) const { return value_ != rhs.value_; }
  bool operator <=(const Note& rhs) const { return value_ <= rhs.value_; }
  bool operator >=(const Note& rhs) const { return value_ >= rhs.value_; }
  bool operator  <(const Note& rhs) const { return value_  < rhs.value_; }
  bool operator  >(const Note& rhs) const { return value_  > rhs.value_; }

  operator int() const { return value(); }

private:
  inline static std::string const sharpTag_ = "♯";
  inline static std::array<std::string, 12> const labels_ = {
    "C", "C", "D", "D", "E", "F", "F", "G", "G", "A", "A", "B"
  };

  int value_;
  size_t note_;
};

} // namespace SF2::MIDI
