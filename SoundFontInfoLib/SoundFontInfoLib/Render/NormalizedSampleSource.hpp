// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <os/log.h>
#include <os/signpost.h>
#include <Accelerate/Accelerate.h>
#include <AudioToolbox/AUParameters.h>

#include <vector>

#include "Logger.hpp"
#include "DSP/DSP.hpp"
#include "Entity/SampleHeader.hpp"
#include "Render/Sample/Bounds.hpp"

namespace SF2::Render {

/**
 Contains a collection of audio samples that range between -1.0 and 1.0. The values are derived from the
 16-bit values found in the SF2 file. Note that this conversion is done on-demand via the first call to
 `load`.
 */
class NormalizedSampleSource {
public:

  static constexpr Float normalizationScale = Float(1.0) / Float(1 << 15);

  /**
   Construct a new normalized buffer of samples.

   @param samples pointer to the first 16-bit sample in the SF2 file
   @param header defines the range of samples to use for a sound
   */
  NormalizedSampleSource(const int16_t* samples, const Entity::SampleHeader& header) :
  samples_(header.endIndex() - header.startIndex()), header_{header}, allSamples_{samples} {}

  /**
   Load the samples into buffer if not already available.
   */
  inline void load() const { if (!loaded_) loadNormalizedSamplesAccelerated(); }

  /// @returns true if the buffer is loaded
  bool isLoaded() const { return loaded_; }

  /// @returns number of samples in the canonical representation
  size_t size() const { return loaded_ ? samples_.size() : 0; }

  void unload() const {
    loaded_ = false;
    std::fill(samples_.begin(), samples_.end(), 0.0);
  }

#ifdef DEBUG
  /**
   Obtain the sample at the given index

   @param index the index to use
   @returns sample at the index
   */
  Float operator[](size_t index) const { return samples_.at(index); }
#else
  /**
   Obtain the sample at the given index

   @param index the index to use
   @returns sample at the index
   */
  Float operator[](size_t index) const { return samples_[index]; }
#endif

  /// @returns the sample header ('shdr') of the sample stream being rendered
  const Entity::SampleHeader& header() const { return header_; }

  /**
   Obtain the max magnitude seen in the samples of the loop specified by the given bounds.
   */
  Float maxMagnitudeOfLoop() const { return maxMagnitudeOfLoop_; }

private:

  // Rudimentary testing with -O0 shows this to be 40% faster than the loop.
  void loadNormalizedSamplesAccelerated() const {
    os_signpost_id_t signpost = os_signpost_id_generate(log_);
    size_t size = header_.endIndex() - header_.startIndex();
    assert(samples_.size() == size);
    assert(!loaded_);

    os_signpost_interval_begin(log_, signpost, "loadNormalizedSamples", "begin - size: %ld", size);
    auto pos = allSamples_ + header_.startIndex();
    Float scale = (1 << 15);
    vDSP_vflt16D(pos, 1, samples_.data(), 1, size);
    vDSP_vsdivD(samples_.data(), 1, &scale, samples_.data(), 1, size);
    os_signpost_interval_end(log_, signpost, "loadNormalizedSamples", "end");

    maxMagnitudeOfLoop_ = getMaxMagnitudeOfLoop<Float>();
    loaded_ = true;
  }

  void loadNormalizedSamplesNormal() const {
    os_signpost_id_t signpost = os_signpost_id_generate(log_);
    size_t size = header_.endIndex() - header_.startIndex();
    assert(samples_.size() == size);
    assert(!loaded_);

    os_signpost_interval_begin(log_, signpost, "loadNormalizedSamples", "begin - size: %ld", size);
    auto pos = allSamples_ + header_.startIndex();
    for (size_t index = 0; index < size; ++index) {
      samples_[index] = *pos++ * normalizationScale;
    }
    os_signpost_interval_end(log_, signpost, "loadNormalizedSamples", "end");

    maxMagnitudeOfLoop_ = getMaxMagnitudeOfLoop<Float>();

    loaded_ = true;
  }

  template <typename T>
  T getMaxMagnitudeOfLoop() const {
    T maxMagnitude{0.0};
    auto bounds{Sample::Bounds::make(header_)};
    using Proc = std::function<void(const T*, vDSP_Stride, T*, vDSP_Length)>;
    Proc proc = nullptr;
    if constexpr (std::is_same<T, float>::value) proc = vDSP_maxmgv;
    if constexpr (std::is_same<T, double>::value) proc = vDSP_maxmgvD;
    proc(samples_.data() + bounds.startLoopPos(), 1, &maxMagnitude, bounds.loopSize());
    return maxMagnitude;
  }

  mutable std::vector<Float> samples_;
  const Entity::SampleHeader& header_;

  const int16_t* allSamples_;
  mutable bool loaded_{false};
  mutable Float maxMagnitudeOfLoop_;

  inline static Logger log_{Logger::Make("Render.Sample", "NormalizedSampleSource")};
};

} // namespace SF2::Render::Sample::Source
