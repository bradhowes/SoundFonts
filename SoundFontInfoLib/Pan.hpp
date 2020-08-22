// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "Synthesizer.hpp"

namespace SF2 {

class Pan {
    Pan(double position);

    void setPosition(double position) {
        // panlft = synthParams.sinquad[(int)(panlft * synthParams.sqNdx)];
        // panrgt = synthParams.sinquad[(int)(panrgt * synthParams.sqNdx)];
        leftScaling_ = 
    }

    double leftScaling() const { return leftScaling_; }
    double rightScaling() const { return rightScaling_; }

private:
    double position_;
    double leftScaling_;
    double rightScaling_;
};

}
