//// Copyright © 2020 Brad Howes. All rights reserved.
//
//#pragma once
//
//#include "Format.hpp"
//#include "Pos.hpp"
//
//namespace SF2 {
//
///**
// Manages a pointer into a collection of bytes and provides a mechanism for copying the bytes into an
// object's memory layout for quick instantiation from a SF2 file.
// */
//class BinaryStream
//{
//public:
//
//    /**
//     Construct stream.
//
//     - parameter pos: pointer to the first byte to read
//     - parameter available: number of bytes available for reading
//     */
//    BinaryStream(Pos pos) : pos_{pos} {}
//
//    /**
//     Determine if the stream is empty
//
//     - returns: true if empty
//     */
//    constexpr explicit operator bool() const { return pos_.operator bool(); }
//
//    /**
//     Copy bytes from stream into an object's memory. The number of bytes to copy is determined by the template
//     argument's `size` property.
//
//     - parameter destination: the location to begin writing
//     */
//    template <typename T>
//    void copyInto(T* destination) {
//        if (sizeof(T) != T::size) throw Format::error;
//        copyInto(destination, T::size);
//    }
//
//    /**
//     Copy `size` bytes from stream starting at the given memory location.
//
//     - parameter destination: the location to begin writing
//     - parameter size: the number of bytes to write
//     */
//    void copyInto(void* destination, size_t size) {
//        if (pos_) throw Format::error;
//        pos_ = pos_.readInto(destination, size);
//    }
//
//    constexpr size_t available() const { return pos_.available(); }
//
//private:
//    Pos pos_;
//};
//
//}
