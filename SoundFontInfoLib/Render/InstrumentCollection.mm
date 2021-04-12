// Copyright © 2020 Brad Howes. All rights reserved.

#include "IO/File.hpp"
#include "InstrumentCollection.hpp"

using namespace SF2::Render;

InstrumentCollection::InstrumentCollection(const IO::File& file) : instruments_{}
{
    auto count = file.instruments().size();
    instruments_.reserve(count);
    for (const Entity::Instrument& configuration : file.instruments().slice(0, count)) {
        instruments_.emplace_back(file, configuration);
    }
}
