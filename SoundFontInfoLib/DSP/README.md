#  DSP Namespace

Collection of common routines used for digital signal processing. Many of these are specific to working with MIDI and SF2 concepts.
There are several lookup tables that convert from a MIDI value in the range [0-127] to a floating-point value. These are generated at 
compile-time for fast loading at runtime.

# Generated Tables

There are some lookup tables that are generated at compile time in order to speed up startup time. These tables are defined in
`DSP/DSPTables.hpp` and `MIDI/ValueTransformer.hpp`. There is a custom build phase for `SoundFontInfoLib` called
`Create DSPGenerated.cpp File` that generates this file.

The `DSPGenerated.cpp` file points to a spot in the `DerivedData` project folder for intermediate build products. In a clean build, it will be 
colored red, but if all is good it will be built when SoundFontInfoLib is built.

There is a command-line tool called `DSPGenerator` which runs in the custom build phase mentioned above. See the files in the 
`DSPGenerator` folder.
