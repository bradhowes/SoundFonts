// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "Synthesizer.hpp"

namespace SF2 {
namespace Render {

class Pan {
    Pan(double position);

    void setPosition(double position) {
        // panlft = synthParams.sinquad[(int)(panlft * synthParams.sqNdx)];
        // panrgt = synthParams.sinquad[(int)(panrgt * synthParams.sqNdx)];
        leftScaling_ = 
    }

    auto leftScaling() const -> auto { return leftScaling_; }
    auto rightScaling() const -> auto { return rightScaling_; }

private:
    double position_;
    double leftScaling_;
    double rightScaling_;
};

}
}
