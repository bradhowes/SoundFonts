// Copyright © 2020 Brad Howes. All rights reserved.

#include <os/log.h>

#include "SampleBuffer.hpp"

using namespace SF2::Render;

SampleBuffer::SampleBuffer(const int16_t* begin, size_t size, size_t loopStart, size_t loopEnd)
: samples_{}, loopStart_{loopStart}, loopEnd_{loopEnd}, log_(os_log_create("SF2", "SampleBuffer"))
{
    // auto signpost = os_signpost_id_generate(log_);
    // os_signpost_interval_begin(log_, signpost, "SampleBuffer", "%ld", size);
    samples_.reserve(size);
    while (size-- > 0) {
        samples_.emplace_back(*begin++ / 32767.0);
    }
    // os_signpost_interval_end(log_, signpost, "SampleBuffer");
}
