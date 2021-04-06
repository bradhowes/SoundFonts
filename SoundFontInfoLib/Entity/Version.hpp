// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <cstdint>
#include <iostream>

#include "IO/Pos.hpp"

namespace SF2 {
namespace Entity {

/**
 Memory layout of a 'iver' entry in a sound font resource. Holds the version info of a file.
 */
class Version {
public:
    constexpr static size_t size = 4;

    Version() : wMajor{0}, wMinor{0} {}

    /**
     Constructor that reads from file.

     @param pos location to read from
     */
    void load(const IO::Pos& pos) {
        assert(sizeof(*this) == size);
        pos.readInto(*this);
    }

    /**
     Utility for displaying bag contents on `std::cout`

     @param indent the prefix to write out before each line
     */
    void dump(const std::string& indent) const
    {
        std::cout << indent << "major: " << wMajor << " minor: " << wMinor << std::endl;
    }

private:
    uint16_t wMajor;
    uint16_t wMinor;
};

}
}
