// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <cassert>
#include <string>
#include <array>

namespace SF2 {
namespace Render {

/**
 A MIDI note representation. MIDI note values range from 0 to 255, and so does this.
 */
class Note {
public:

    /**
     Construct new note.

     @param value the MIDI value to represent
     */
    explicit Note(int value) : value_{uint8_t(value)}, index_{uint8_t(value % 12)} {
        assert(value >= 0 && value <= 255);
    }

    /// @returns the octave that the note resides in
    int octave() const { return value_ / 12 - 1; }

    /// @returns true if the note is accented (sharp / flat)
    bool accented() const { return (index_ < 5 && (index_ & 1) == 1) || (index_ > 5 && (index_ & 1) == 0); }

    /// @returns textual representation of the note (shows a sharp for accented notes)
    std::string label() const { return noteLabels[index_] + std::to_string(octave()) + (accented() ? sharpTag : ""); }

    int value() const { return value_; }

    static std::string const sharpTag;
    static std::array<std::string, 12> const noteLabels;

    bool operator ==(const Note& rhs) const { return value_ == rhs.value_; }
    bool operator !=(const Note& rhs) const { return value_ != rhs.value_; }
    bool operator <=(const Note& rhs) const { return value_ <= rhs.value_; }
    bool operator >=(const Note& rhs) const { return value_ >= rhs.value_; }
    bool operator <(const Note& rhs) const { return value_ < rhs.value_; }
    bool operator >(const Note& rhs) const { return value_ > rhs.value_; }

    operator int() const { return value_; }

private:
    uint8_t value_;
    uint8_t index_;
};

} // namespace Render
} // namespace SF2
