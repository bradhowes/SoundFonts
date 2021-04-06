// Copyright © 2020 Brad Howes. All rights reserved.
//
// Loosely based on iffdigest v0.3 by Andrew C. Bulhak. This code has been modified to *only* work on IFF_FMT_RIFF, and
// it safely parses bogus files by throwing an IFF_FMT_ERROR exception anytime there is an access outside of valid
// memory. Additional cleanup and rework for modern C++ compilers.

#pragma once

#include <string>
#include <vector>

namespace SF2 {
namespace IO {

/**
 SoundFont file parser.
 */
class Parser {
public:

    /// Extracted preset information from the SF2 file.
    struct PresetInfo {
        PresetInfo(std::string n, uint16_t b, uint16_t p) : name{n}, bank{b}, preset{p} {}

        std::string name;
        uint16_t bank;
        uint16_t preset;
    };

    /// Extract SF2 info
    struct Info {

        /// The name embedded in the SF2 file
        std::string embeddedName;
        std::string embeddedAuthor;
        std::string embeddedCopyright;
        std::string embeddedComment;

        /// The collection of preset definitions from the SF2 file
        std::vector<PresetInfo> presets;
    };

    /**
     Attempt to parse a SoundFont resource. Any failures to do so will throw a FormatError exception. Note that this
     really just parses any RIFF format. We postpone the SF2 evaluation until the initial loading is done.

     - parameter fd: file descriptor of the SF2 file to read from for data
     - parameter size: the number of bytes available for processing
     */
    static Info parse(int fd, size_t size);
};

}
}
