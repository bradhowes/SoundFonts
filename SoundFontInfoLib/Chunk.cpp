// Copyright © 2020 Brad Howes. All rights reserved.

#include <iostream>

#include "Chunk.hpp"
#include "ChunkItems.hpp"
#include "SFBag.hpp"
#include "SFGenerator.hpp"
#include "SFInstrument.hpp"
#include "SFModulator.hpp"
#include "SFPreset.hpp"
#include "SFSample.hpp"
#include "Voice.hpp"

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
            case Tags::phdr: ChunkItems<SFPreset>(*this).dump(indent + ' '); break;
            case Tags::pbag: ChunkItems<SFBag>(*this).dump(indent + ' '); break;
            case Tags::pgen: ChunkItems<SFGenerator>(*this).dump(indent + ' '); break;
            case Tags::pmod: ChunkItems<SFModulator>(*this).dump(indent + ' '); break;
            case Tags::inst: ChunkItems<SFInstrument>(*this).dump(indent + ' '); break;
            case Tags::ibag: ChunkItems<SFBag>(*this).dump(indent + ' '); break;
            case Tags::igen: ChunkItems<SFGenerator>(*this).dump(indent + ' '); break;
            case Tags::imod: ChunkItems<SFModulator>(*this).dump(indent + ' '); break;
            case Tags::shdr: ChunkItems<SFSample>(*this).dump(indent + ' '); break;
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
