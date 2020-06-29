// Copyright © 2020 Brad Howes. All rights reserved.

#ifndef ChunkItems_hpp
#define ChunkItems_hpp

#include <iostream>

#include "Chunk.hpp"
#include "Parser.hpp"

namespace SF2 {

template <typename T, size_t S>
struct ChunkItems
{
    using ItemType = T;

    static constexpr size_t itemSize = S;

    ChunkItems(const Chunk& source) : source_{source}, items_{}
    {
        items_.reserve(source.size() / itemSize);
        load();
    }

    size_t size() const { return items_.size(); }

    const ItemType& operator[](size_t index) const { return items_[index]; }

    typename std::vector<ItemType>::const_iterator begin() const { return items_.begin(); }

    typename std::vector<ItemType>::const_iterator end() const { return items_.end(); }

    void load()
    {
        const char* p = source_.dataPtr();
        const char* end = p + source_.size() - itemSize;;
        while (p < end) {
            ItemType entry;
            if (end - p < itemSize) throw FormatError;
            p = entry.load(p, end - p);
            items_.emplace_back(entry);
        }

    }

    void dump(const std::string& indent ) const {
        std::cout << indent << "count: " << size() << std::endl;
        auto index = 0;
        std::for_each(begin(), end(), [&](const ItemType& item) {
            item.dump(indent, index);
            index += 1;
        });
    }

    const Chunk& source_;
    std::vector<ItemType> items_;
};

}

#endif /* ChunkItems_hpp */
