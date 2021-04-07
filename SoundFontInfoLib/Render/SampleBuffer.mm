// Copyright © 2020 Brad Howes. All rights reserved.

#include <os/log.h>
#include <os/signpost.h>

#include "SampleBuffer.hpp"

using namespace SF2::Render;

void
SampleBuffer::loadNormalizedSamples() const
{
    static constexpr AUValue scale = 1.0 / 32768.0;

    os_log_t log = os_log_create("SF2", "loadSamples");
    auto signpost = os_signpost_id_generate(log);
    size_t size = header_.end() - header_.begin();
    os_signpost_interval_begin(log, signpost, "SampleBuffer", "begin - size: %ld", size);
    samples_.reserve(size);
    samples_.clear();
    auto pos = allSamples_ + header_.begin();
    while (size-- > 0) samples_.emplace_back(*pos++ * scale);
    os_signpost_interval_end(log, signpost, "SampleBuffer", "end");
}
