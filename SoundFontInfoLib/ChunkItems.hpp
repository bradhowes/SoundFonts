// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <iostream>

#include "BinaryStream.hpp"
#include "Chunk.hpp"
#include "Parser.hpp"

namespace SF2 {

template <typename T>
struct ChunkItems
{
    using ItemType = T;
    static constexpr size_t itemSize = T::size;

    ChunkItems(Chunk const& source) : source_{source}, items_{}
    {
        items_.reserve(source.size() / itemSize);
        load();
    }

    size_t size() const { return items_.size(); }

    ItemType const& operator[](size_t index) const { return items_[index]; }

    typename std::vector<ItemType>::const_iterator begin() const { return items_.begin(); }

    typename std::vector<ItemType>::const_iterator end() const { return items_.end(); }

    void load()
    {
        BinaryStream is(source_.dataPtr(), source_.size());
        while (is) items_.emplace_back(is);
    }

    void dump(std::string const& indent ) const {
        auto index = 0;

        // All collections in SF2 end with a sentinal entry that is *not* a member of the collection.
        std::cout << " count: " << (size() - 1) << std::endl;
        std::for_each(begin(), end() - 1, [&](ItemType const& item) {
            item.dump(indent, index);
            index += 1;
        });
    }

    Chunk const& source_;
    std::vector<ItemType> items_;
};

}
