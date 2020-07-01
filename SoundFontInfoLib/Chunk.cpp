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
        if (tag_ == Tag::ifil) dumpVersion(data_, size_);
        else if (tag_ == Tag::isng) dumpString(data_, size_);
        else if (tag_ == Tag::inam) dumpString(data_, size_);
        else if (tag_ == Tag::irom) dumpString(data_, size_);
        else if (tag_ == Tag::irom) dumpString(data_, size_);
        else if (tag_ == Tag::iver) dumpVersion(data_, size_);
        else if (tag_ == Tag::icrd) dumpString(data_, size_);
        else if (tag_ == Tag::ieng) dumpString(data_, size_);
        else if (tag_ == Tag::iprd) dumpString(data_, size_);
        else if (tag_ == Tag::icop) dumpString(data_, size_);
        else if (tag_ == Tag::icmt) dumpString(data_, size_);
        else if (tag_ == Tag::isft) dumpString(data_, size_);
        else if (tag_ == Tag::phdr) Preset(*this).dump(indent + ' ');
        else if (tag_ == Tag::pbag) PresetZone(*this).dump(indent + ' ');
        else if (tag_ == Tag::pmod) PresetZoneMod(*this).dump(indent + ' ');
        else if (tag_ == Tag::pgen) PresetZoneGen(*this).dump(indent + ' ');
        else if (tag_ == Tag::inst) Instrument(*this).dump(indent + ' ');
        else if (tag_ == Tag::ibag) InstrumentZone(*this).dump(indent + ' ');
        else if (tag_ == Tag::imod) InstrumentZoneMod(*this).dump(indent + ' ');
        else if (tag_ == Tag::igen) InstrumentZoneGen(*this).dump(indent + ' ');
        else if (tag_ == Tag::shdr) Sample(*this).dump(indent + ' ');

        std::cout << std::endl;
    }
    else {
        auto ourIndent = indent + " ";
        std::cout << std::endl;
        std::for_each(begin(), end(), [ourIndent](Chunk const& chunk) { chunk.dump(ourIndent); });
    }
}
