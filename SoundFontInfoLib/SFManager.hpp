// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <memory>

#include "Instrument.hpp"
#include "Preset.hpp"
#include "SFFile.hpp"

namespace SF2 {

class SFManager {
public:

    explicit SFManager(std::string const& path)
    : file_{new SFFile(path)}, instruments_{*file_}, presets_{*file_, instruments_} {}

    explicit SFManager(SFFile const* file)
    : file_{file}, instruments_{*file}, presets_{*file, instruments_} {}

    PresetCollection const& presets() const { return presets_; }

private:
    std::unique_ptr<SFFile const> file_;
    InstrumentCollection instruments_;
    PresetCollection presets_;
};

}
