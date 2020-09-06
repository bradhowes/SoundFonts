// Copyright © 2020 Brad Howes. All rights reserved.

#include "SFFile.hpp"

#include "Instrument.hpp"
#include "Preset.hpp"

using namespace SF2;

void
SFFile::buildWith(Chunk const& chunk)
{
//    if (chunk.dataPtr() != nullptr) {
//
//        // Convert the data in a chunk into a collection of C/C++ structs that mirror the SF2 spec (mostly).
//        // This is pretty quick as-is, but if we were free from memory layout constraints, we could just point
//        // to the memory directly.
//        switch (chunk.tag().toInt()) {
//            case Tags::phdr: presets.load(chunk); break;
//            case Tags::pbag: presetZones.load(chunk); break;
//            case Tags::pgen: presetZoneGenerators.load(chunk); break;
//            case Tags::pmod: presetZoneModulators.load(chunk); break;
//            case Tags::inst: instruments.load(chunk); break;
//            case Tags::ibag: instrumentZones.load(chunk); break;
//            case Tags::igen: instrumentZoneGenerators.load(chunk); break;
//            case Tags::imod: instrumentZoneModulators.load(chunk); break;
//            case Tags::shdr: samples.load(chunk); break;
//            case Tags::smpl:
//                sampleData = chunk.bytePtr();
//                sampleDataEnd = chunk.bytePtr() + chunk.size();
//                break;
//        }
//    }
//    else {
//        std::for_each(chunk.begin(), chunk.end(), [this](Chunk const& chunk) { buildWith(chunk); });
//    }
}

void
SFFile::validate()
{
    ;
}
