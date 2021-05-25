// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <cassert>

namespace SF2 {

/**
 Collection of types that mirror data structures defined in the SF2 spec. These are all read-only representations.
 */
namespace Entity {

/**
 Base class that offers common functionality for working with entities that are part of a collection.
 */
struct Entity {

    /**
     Calculate the number of bag elements between to items

     @param next the bag index from the following item in the collection
     @param current the bag index from the current item in the collection
     */
    static uint16_t calculateSize(uint16_t next, uint16_t current) {
        assert(next >= current);
        return next - current;
    }

    /**
     Obtain reference to the next item in a collection. For a *valid* SF2 file, this is OK to do because all
     collections contain a sentinel value to mark the end of the collection.

     @param obj the object address to calculate with
     @returns reference to next object
     */
    template <typename T>
    static const T& next(const T* obj) { return *(obj + 1); }
};

} // end namespace Entity
} // end namespace SF2
