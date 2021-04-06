// Copyright © 2021 Brad Howes. All rights reserved.

#pragma once

#include <algorithm>
#include <cmath>

namespace DSP {

/**
 Translate value in range [0, +1] into one in range [-1, +1]

 @param modulator the value to translate
 @returns value in range [-1, +1]
 */
template <typename T> auto unipolarToBipolar(T modulator) { return 2.0 * modulator - 1.0; }

/**
 Translate value in range [-1, +1] into one in range [0, +1]

 @param modulator the value to translate
 @returns value in range [0, +1]
 */
template <typename T> auto bipolarToUnipolar(T modulator) { return 0.5 * modulator + 0.5; }

/**
 Perform linear translation from a value in range [0.0, 1.0] into one in [minValue, maxValue].

 @param modulator the value to translate
 @param minValue the lowest value to return when modulator is 0
 @param maxValue the highest value to return when modulator is +1
 @returns value in range [minValue, maxValue]
 */
template <typename T> auto unipolarModulation(T modulator, T minValue, T maxValue) {
    return std::clamp<T>(modulator, 0.0, 1.0) * (maxValue - minValue) + minValue;
}

/**
 Perform linear translation from a value in range [-1.0, 1.0] into one in [minValue, maxValue]

 @param modulator the value to translate
 @param minValue the lowest value to return when modulator is -1
 @param maxValue the highest value to return when modulator is +1
 @returns value in range [minValue, maxValue]
 */
template <typename T> auto bipolarModulation(T modulator, T minValue, T maxValue) {
    auto mid = (maxValue - minValue) * 0.5;
    return std::clamp<T>(modulator, -1.0, 1.0) * mid + mid + minValue;
}

/**
 Estimate sin() value from a radian angle between -PI and PI.
 Derived from code in "Designing Audio Effect Plugins in C++" by Will C. Pirkle (2019)
 As can be seen in the unit test `testParabolicSineAccuracy`, the worst-case deviation from
 std::sin is ~0.0011.

 @param angle value between -PI and PI
 @returns approximate sin value
 */
template <typename T> auto parabolicSine(T angle) {
    constexpr T B = 4.0 / M_PI;
    constexpr T C = -4.0 / (M_PI * M_PI);
    constexpr T P = 0.225;
    const T y = B * angle + C * angle * std::abs(angle);
    return P * y * (std::abs(y) - 1.0) + y;
}

} // DSP namespace
