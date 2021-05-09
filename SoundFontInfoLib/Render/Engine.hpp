// Copyright © 2021 Brad Howes. All rights reserved.

#pragma once

#import <os/log.h>
#import <AVFoundation/AVFoundation.h>

#import "Types.hpp"
#import "Render/Instrument.hpp"
#import "Render/Preset.hpp"

namespace SF2 {
namespace Render {

class Engine : public T {
public:

    Engine(double sampleRate);

    const Preset& preset(size_t index) const;
    const Preset* lookup(short bank, short preset) const;

private:
};

} // namespace Render
} // namespace SF2
