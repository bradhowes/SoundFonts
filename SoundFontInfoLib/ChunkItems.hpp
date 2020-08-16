// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <iostream>

#include "BinaryStream.hpp"
#include "Chunk.hpp"
#include "Parser.hpp"

namespace SF2 {

/**
 Container of SF2 entities. All SF2 containers are homogenous (all entities have the same type).
 */
template <typename T>
class ChunkItems
{
public:
    using ItemType = T;
    static constexpr size_t itemSize = T::size;

    ChunkItems() : items_{} {}

    /**
     Construct a new container by creating individual SF2 entities from the given source.

     - parameter source: the bytes that will be used to generate the entities
     */
    ChunkItems(Chunk const& source) : items_{}
    {
        // This is a hard constraint: the number of items is in the collection is defined by the overall source size
        // since there is no padding involved in the SF2 file format. There resulting vector of items may be larger
        // due to memory layout, but the item count will be the same.
        load(source);
    }

    void load(Chunk const& source)
    {
        items_.reserve(source.size() / itemSize);
        BinaryStream is(source.bytePtr(), source.size());
        while (is) items_.emplace_back(is);
    }

    /**
     Get the number of items in this collection

     - returns: number of items in collection
     */
    size_t size() const { return items_.size(); }

    /**
     Obtain a (read-only) reference to an entity in the collection.

     - parameter index: the entity to fetch
     - returns: entity
     */
    ItemType const& operator[](size_t index) const { return items_.at(index); }

    /**
     Obtain iterator to the start of the collection

     - returns: iterator to start of the collection
     */
    typename std::vector<ItemType>::const_iterator begin() const { return items_.begin(); }

    /**
     Obtain iterator at the end of the collection

     - returns: iterator at the end of the collection
     */
    typename std::vector<ItemType>::const_iterator end() const { return items_.end(); }

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
    std::vector<ItemType> items_;
};

}
