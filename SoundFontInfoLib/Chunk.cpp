// Copyright © 2020 Brad Howes. All rights reserved.

#include <iostream>

#include "Chunk.hpp"
#include "Instrument.hpp"
#include "InstrumentZone.hpp"
#include "InstrumentZoneGen.hpp"
#include "InstrumentZoneMod.hpp"
#include "Preset.hpp"
#include "PresetZone.hpp"
#include "PresetZoneGen.hpp"
#include "PresetZoneMod.hpp"
#include "Sample.hpp"

using namespace SF2;

static void dumpVersion(char const* data, size_t size)
{
    auto ptr = reinterpret_cast<int16_t const*>(data);
    std::cout << "major: " << ptr[0] << " minor: " << ptr[1];
}

static void dumpString(char const* data, size_t size)
{
    std::cout << "'" << data << "'";
}

void
Chunk::dump(std::string const& indent) const
{
    std::cout << indent << tag_.toString();
    if (data_ != nullptr) {
        std::cout << " size: " << size_ << ' ';
        switch (tag_.toInt()) {
            case Tags::phdr: Preset(*this).dump(indent + ' '); break;
            case Tags::pbag: PresetZone(*this).dump(indent + ' '); break;
            case Tags::pmod: PresetZoneMod(*this).dump(indent + ' '); break;
            case Tags::pgen: PresetZoneGen(*this).dump(indent + ' '); break;
            case Tags::inst: Instrument(*this).dump(indent + ' '); break;
            case Tags::ibag: InstrumentZone(*this).dump(indent + ' '); break;
            case Tags::imod: InstrumentZoneMod(*this).dump(indent + ' '); break;
            case Tags::igen: InstrumentZoneGen(*this).dump(indent + ' '); break;
            case Tags::shdr: Sample(*this).dump(indent + ' '); break;
            case Tags::ifil: dumpVersion(data_, size_); break;
            case Tags::iver: dumpVersion(data_, size_); break;
            default: dumpString(data_, size_); break;
        }
        std::cout << std::endl;
    }
    else {
        auto ourIndent = indent + " ";
        std::cout << std::endl;
        std::for_each(begin(), end(), [ourIndent](Chunk const& chunk) { chunk.dump(ourIndent); });
    }
}
