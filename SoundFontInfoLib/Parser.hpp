// Copyright © 2020 Brad Howes. All rights reserved.
//
// Loosely based on iffdigest v0.3 by Andrew C. Bulhak. This code has been modified to *only* work on IFF_FMT_RIFF, and
// it safely parses bogus files by throwing an IFF_FMT_ERROR exception anytime there is an access outside of valid
// memory. Additional cleanup and rework for modern C++ compilers.

#pragma once

#include <vector>

namespace SF2 {

/**
 SoundFont file parser.
 */
class Parser {
public:

    struct Preset {
        Preset(std::string n, uint16_t b, uint16_t p) : name{n}, bank{b}, preset{p} {}
        std::string name;
        uint16_t bank;
        uint16_t preset;
    };

    struct Info {
        std::string embeddedName;
        std::vector<Preset> presets;
    };

    /**
     Attempt to parse a SoundFont resource. Any failures to do so will throw a FormatError exception. Note that this really just parses any RIFF
     format. We postpone the SF2 evaluation until the initial loading is done.
     */
    static Info parse(int fd, size_t size);
};

}
