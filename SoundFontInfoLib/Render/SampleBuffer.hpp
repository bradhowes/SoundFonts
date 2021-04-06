// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <os/log.h>
#include <AudioToolbox/AUParameters.h>

#include <limits>
#include <vector>

namespace SF2 {
namespace Render {

class SampleBuffer {
public:

    SampleBuffer(const int16_t* begin, size_t size, size_t loopStart, size_t loopEnd);

private:
    std::vector<AUValue> samples_;
    size_t loopStart_;
    size_t loopEnd_;
    os_log_t log_;
};

}
}
