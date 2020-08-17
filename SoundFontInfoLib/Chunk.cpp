// Copyright © 2020 Brad Howes. All rights reserved.

#include <iostream>

#include "Chunk.hpp"
#include "Instruments.hpp"
#include "Presets.hpp"
#include "Samples.hpp"
#include "Zones.hpp"
#include "ZoneGenerators.hpp"
#include "ZoneModulators.hpp"

using namespace SF2;

static void dumpVersion(void const* data, size_t size)
{
    auto ptr = reinterpret_cast<int16_t const*>(data);
    std::cout << "major: " << ptr[0] << " minor: " << ptr[1];
}

static void dumpString(void const* data, size_t size)
{
    std::cout << "'" << static_cast<char const*>(data) << "'";
}

void
Chunk::dump(std::string const& indent) const
{
    std::cout << indent << tag_.toString();
    if (data_ != nullptr) {
        std::cout << " size: " << size_ << ' ';
        switch (tag_.toInt()) {
            case Tags::phdr: Presets(*this).dump(indent + ' '); break;
            case Tags::pbag: Zones(*this).dump(indent + ' '); break;
            case Tags::pgen: ZoneGenerators(*this).dump(indent + ' '); break;
            case Tags::pmod: ZoneModulators(*this).dump(indent + ' '); break;
            case Tags::inst: Instruments(*this).dump(indent + ' '); break;
            case Tags::ibag: Zones(*this).dump(indent + ' '); break;
            case Tags::imod: ZoneModulators(*this).dump(indent + ' '); break;
            case Tags::igen: ZoneGenerators(*this).dump(indent + ' '); break;
            case Tags::shdr: Samples(*this).dump(indent + ' '); break;
            case Tags::ifil: dumpVersion(data_, size_); break;
            case Tags::iver: dumpVersion(data_, size_); break;
            case Tags::smpl: break;
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
