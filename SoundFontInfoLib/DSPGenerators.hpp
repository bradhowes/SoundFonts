// Copyright © 2021 Brad Howes. All rights reserved.

#pragma once

#include <iostream>

#include "DSP.hpp"
#include "MIDI/ValueTransformer.hpp"

namespace SF2 {
namespace DSP {
namespace Tables {

/**
 Table value generators and initializers. This is only used by the DSPGenerators program which creates the DSP tables
 at compile time for quick loading at runtime.
 */
struct Generator {

    /**
     Generic table generator. The template type `T` must define a `TableSize` class parameter that gives the size of the
     table to initialize, and it must define a `Value` class method that takes an index value and returns a value to
     put into the table.

     @param os the stream to write to
     @param name the name of the table to initialize
     */
    template <typename T>
    void generate(std::ostream& os, const std::string& name) {
        os << "const std::array<double, " << name << "::TableSize> " << name << "::lookup_ = {\n";
        for (auto index = 0; index < T::TableSize; ++index) {
            os << T::value(index) << ",\n";
        }
        os << "};\n\n";
    }

    /**
     Generic ValueTransformer table initializer.

     @param os the stream to write to
     @param proc the function that generates a value for a given table index
     @param name the table name to initialize
     @param bipolar if true, initialize a bipolar table; otherwise, a unipolar one (default).
     */
    void generateTransform(std::ostream& os, std::function<double(int)> proc, const std::string& name,
                           bool bipolar = false) {
        os << "const ValueTransformer::TransformArrayType ValueTransformer::" << name;
        if (bipolar) os << "Bipolar";
        os << "_ = {\n";

        for (auto index = 0; index < MIDI::ValueTransformer::TableSize; ++index) {
            os << (bipolar ? unipolarToBipolar(proc(index)) : proc(index)) << ",\n";
        }
        os << "};\n\n";
    }

    Generator(std::ostream& os);
};

}
}
}
