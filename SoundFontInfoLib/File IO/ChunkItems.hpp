// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <algorithm>
#include <functional>
#include <iostream>

#include "Chunk.hpp"

namespace SF2 {

/**
 Container of SF2 entities. All SF2 containers are homogenous (all entities have the same type).
 */
template <typename T>
class ChunkItems
{
public:
    using ItemType = T;
    using ItemCollection = std::vector<ItemType>;
    using const_iterator = typename std::vector<ItemType>::const_iterator;
    using ItemRefCollection = std::vector<std::reference_wrapper<ItemType const>>;


    static constexpr size_t itemSize = T::size;

    ChunkItems() : items_{} {}

    /**
     Construct a new container by creating individual SF2 entities from the given source.

     - parameter source: the bytes that will be used to generate the entities
     */
    explicit ChunkItems(ChunkList const& source) : items_{}
    {
        load(source);
    }

    void load(Chunk const& source)
    {
        size_t size = source.size() / itemSize - 1;
        items_.reserve(size);
        Pos pos = source.begin();
        Pos end = source.begin().advance(size * itemSize);
        while (pos < end) {
            items_.emplace_back(pos);
        }
        // items_.pop_back();
    }

    /**
     Get the number of items in this collection

     - returns: number of items in collection
     */
    size_t size() const { return items_.size(); }
    bool empty() const { return items_.empty(); }
    
    /**
     Obtain a (read-only) reference to an entity in the collection.

     - parameter index: the entity to fetch
     - returns: entity
     */
    ItemType const& operator[](size_t index) const { return items_.at(index); }

    ItemRefCollection slice(size_t first, size_t count) const
    {
        assert(first < size() && first + count <= size());
        return ItemRefCollection(items_.begin() + first, items_.begin() + first + count);
    }

    /**
     Obtain iterator to the start of the collection

     - returns: iterator to start of the collection
     */
    const_iterator begin() const { return items_.begin(); }

    /**
     Obtain iterator at the end of the collection

     - returns: iterator at the end of the collection
     */
    const_iterator end() const { return items_.end(); }

    void dump(std::string const& indent ) const {
        auto index = 0;

        // All collections in SF2 end with a sentinal entry that is *not* a member of the collection.
        std::cout << " count: " << (size() - 1) << std::endl;
        std::for_each(begin(), end() - 1, [&](ItemType const& item) {
            item.dump(indent, index);
            index += 1;
        });
    }


private:
    ItemCollection items_;

    friend class SFFile;
};

}
