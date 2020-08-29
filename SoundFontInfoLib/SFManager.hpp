// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <memory>

#include "InstrumentCollection.hpp"
#include "PresetCollection.hpp"
#include "SFFile.hpp"

namespace SF2 {

class SFManager {
public:

    explicit SFManager(std::string const& path)
    : file_{SFFile::Make(path)}, instruments_{file_}, presets_{file_, instruments_} {}

    SFFile const& fileData() const { return file_; }
    PresetCollection const& presets() const { return presets_; }
    InstrumentCollection const& instruments() const { return instruments_; }

private:
    SFFile file_;
    InstrumentCollection instruments_;
    PresetCollection presets_;
};

}
