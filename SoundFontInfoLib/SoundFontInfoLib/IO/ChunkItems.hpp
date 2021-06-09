// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <algorithm>
#include <functional>
#include <vector>

#include "IO/Chunk.hpp"

namespace SF2::IO {

struct ChunkItemsSupport {
    static void beginDump(size_t size);
};

/**
 Container of SF2 entities. All SF2 containers are homogenous (all entities in the container have the same type).
 Compared to the `ChunkType` type, this class holds actual values from an SF2 file while the former just knows
 where in the file to find the values.

 Like most of the IO namespace, instances of this class are essentially immutable.

 @arg T is the entity type to hold in this container
 */
template <typename T>
class ChunkItems : private ChunkItemsSupport
{
public:
    using ItemType = T;
    using ItemCollection = std::vector<ItemType>;
    using const_iterator = typename std::vector<ItemType>::const_iterator;
    using ItemRefCollection = std::vector<std::reference_wrapper<ItemType const>>;

    /// Definition of the size in bytes of each item in the collection
    static constexpr size_t itemSize = T::size;

    /// Constructor for an empty collection.
    ChunkItems() : items_{} {}

    /**
     Constructor that loads items from the file.

     @param source defines where to load and how many items to load
     */
    explicit ChunkItems(const ChunkList& source) : items_{}
    {
        load(source);
    }

    /**
     Get the number of items in this collection

     @returns collection count
     */
    size_t size() const { return items_.size() - 1; }

    /**
     Determine if collection is empty

     @returns true if so
     */
    bool empty() const { return items_.size() < 2; }
    
    /**
     Obtain a (read-only) reference to an entity in the collection.

     @param index the entity to fetch
     @returns entity reference
     */
    const ItemType& operator[](size_t index) const {
#ifdef DEBUG
        return items_.at(index);
#else
        return items_[index];
#endif
    }

    /**
     Obtain a read-only slice of the original collection.

     @param first the index of the first item to include in the collection
     @param count the number of items to have in the slice
     @returns the sliced references
     */
    ItemRefCollection slice(size_t first, size_t count) const {
        return (first < size() && first + count <= size())
        ? ItemRefCollection(items_.begin() + first, items_.begin() + first + count)
        : ItemRefCollection();
    }

    /**
     Obtain iterator to the start of the collection

     @returns iterator to start of the collection
     */
    const_iterator begin() const { return items_.begin(); }

    /**
     Obtain iterator at the end of the collection

     @returns iterator at the end of the collection
     */
    const_iterator end() const { return items_.end() - 1; }

    /**
     Utility to dump out the contents of the collection

     @param indent the prefix to use for all output
     */
    void dump(const std::string& indent) const {
        beginDump(size());
        auto index = 0;
        std::for_each(begin(), end(), [&](const ItemType& item) { item.dump(indent, index++); });
    }

private:

    /**
     Read in items found in a chunk

     @param source the location in the file to read
     */
    void load(const Chunk& source)
    {
        size_t count = source.size() / itemSize;
        items_.reserve(count);
        Pos pos = source.begin();
        Pos end = pos.advance(count * itemSize);
        while (pos < end) items_.emplace_back(pos);
    }

    ItemCollection items_;

    friend class File;
};

} // end namespace SF2::IO
