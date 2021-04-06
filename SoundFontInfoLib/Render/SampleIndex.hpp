// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <limits>

#include "Entity/SampleHeader.hpp"

namespace SF2 {
namespace Render {

struct SampleIndex {

    SampleIndex(const Entity::SampleHeader& header, double increment)
    : pos_{0.0}, increment_{increment}, header_{header} {}

    double pos() const { return pos_; }

    void increment(bool canLoop) {
        if (finished()) return;
        pos_ += increment_;
        if (pos_ >= header_.loopEnd() && canLoop) {
            pos_ -= (header_.loopEnd() - header_.loopBegin());
        }
    }

    bool finished() const { return pos_ >= header_.end(); }

private:
    double pos_;
    double increment_;
    const Entity::SampleHeader& header_;
};

} // namespace Render
} // namespace SF2
