// Copyright © 2020 Brad Howes. All rights reserved.

#ifndef ChunkItems_hpp
#define ChunkItems_hpp

#include <iostream>

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
        char const* pos = source_.dataPtr();
        char const* limit = pos + source_.size();
        while (pos < limit) {
            ItemType entry;
            pos = entry.load(pos, limit - pos);
            items_.emplace_back(entry);
        }
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

#endif /* ChunkItems_hpp */
