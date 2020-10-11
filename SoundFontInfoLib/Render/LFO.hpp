// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <cassert>

namespace SF2 {
namespace Render {

class LFO {
public:
    LFO();

    void setFrequency(double frequency);
    double frequency() const { return frequency_; }

    double value();
    double tick();

private:

};

}
}
