// Copyright © 2021 Brad Howes. All rights reserved.

#pragma once

#import <os/log.h>
#import <AVFoundation/AVFoundation.h>

#import "Types.hpp"
#import "Render/Instrument.hpp"
#import "Render/Preset.hpp"

namespace SF2 {
namespace Render {

template <typename T>
class Engine : public T {
public:

    Engine(double sampleRate) : T(), sampleRate_{sampleRate} {}

    void load(const IO::File& file) { T::load(file); };

    const Preset& preset(size_t index) const;
    const Preset* lookup(UByte bank, UByte preset) const;

private:
    std::vector<Preset> presets_;
    std::vector<Instrument> instruments_;
    std::vector<Sample::CanonicalBuffer<AUValue>> sampleBuffers_;
};

} // namespace Render
} // namespace SF2
