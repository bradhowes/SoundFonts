// Copyright © 2021 Brad Howes. All rights reserved.

#pragma once

#include <Accelerate/Accelerate.h>
#include <cmath>
#include <functional>

namespace SF2 {

/**
 Type to use for all floating-point operations in SF2.
 */
using Float = float;

/**
 Collection of function pointers that refer to routines found in Apple's Accelerated framework.
 These are written so that the right routine is chosen depending on the definition of `Float`.
 */
template <typename T>
struct Accelerated
{
  /**
   Type definition for vDSP_vflt16 / vDSP_vflt16D routines that convert a sequence of signed 16-bit integers into
   floating-point values.
   */
  using ConversionProc = std::function<void(const int16_t*, vDSP_Stride, T*, vDSP_Stride, vDSP_Length)>;
  inline static ConversionProc conversionProc = []() {
    if constexpr (std::is_same_v<T, float>) return vDSP_vflt16;
    if constexpr (std::is_same_v<T, double>) return vDSP_vflt16D;
  }();

  /**
   Type definition for vDSP_vsdiv / vDSP_vsdivD routines that divide a sequence of floating-point values by a scalar.
   */
  using ScaleProc = std::function<void(const T*, vDSP_Stride, const T*, T*, vDSP_Stride, vDSP_Length)>;
  inline static ScaleProc scaleProc = []() {
    if constexpr (std::is_same_v<T, float>) return vDSP_vsdiv;
    if constexpr (std::is_same_v<T, double>) return vDSP_vsdivD;
  }();

  /**
   Type definition for vDSP_maxmgv / vDSP_maxmgvD routines that calculate the max magnitude of a sequence of
   floating-point values.
   */
  using MagnitudeProc = std::function<void(const T*, vDSP_Stride, T*, vDSP_Length)>;
  inline static MagnitudeProc magnitudeProc = []() {
    if constexpr (std::is_same_v<T, float>) return vDSP_maxmgv;
    if constexpr (std::is_same_v<T, double>) return vDSP_maxmgvD;
  }();
};

/**
 Generic method that invokes checked or unchecked indexing on a container based on the DEBUG compile flag. When DEBUG
 is defined, invokes `at` which will validate the index prior to use. Otherwise, it invokes `operator []` which does
 unchecked indexing.
 */
template <typename T>
const typename T::value_type& checkedVectorIndexing(const T& container, size_t index)
{
#ifdef DEBUG
  return container.at(index);
#else
  return container[index];
#endif
}

}

