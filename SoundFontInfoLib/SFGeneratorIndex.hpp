// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <iosfwd>
#include <vector>

namespace SF2 {

class SFGeneratorIndex {
public:

    SFGeneratorIndex() : index_{0} {}

    auto index() const -> auto { return index_; }

private:
    const uint16_t index_;
};

}
