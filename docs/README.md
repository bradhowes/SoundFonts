[![CI](https://github.com/bradhowes/SoundFonts/workflows/CI/badge.svg)](https://github.com/bradhowes/SoundFonts)
[![Swift 5.0](https://img.shields.io/badge/Swift-5.0-orange.svg?style=flat)](https://swift.org)
[![AUv3](https://img.shields.io/badge/AU-v3-green.svg)](https://github.com/bradhowes/SoundFonts)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

# SoundFonts Documentation

The SoundFonts app consists of the following components:

* Light-weight app that shows the SoundFonts UI, effects UI, and a keyboard
* AUv3 app extension the just shows the SoundFonts UI
* AUv3 app extension for the reverb audio effect UI
* AUv3 app extension for the delay audio effect UI
* SoundFontsFramework - a Swift framework that contains the common code for the above
* SoundFontInfoLib - an Objective-C++ framework that contains SF2 processing code
* SF2Files - a tiny Swift framework that hosts the embedded SF2 files that are packaged with the app

Due to the current tool chain being used, the documentation is divided into two sections, one for Swift code
and one for Objective-C/C++.

* [Swift Code](swift/index.html)
* [SoundFontInfoLib (C++)](SoundFontInfoLib/index.html)
