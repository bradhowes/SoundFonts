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

namespace SF2::Render {

/**
 Contains a collection of audio samples that range between -1.0 and 1.0. The values are derived from the
 16-bit values found in the SF2 file. Note that this conversion is done on-demand via the first call to
 `load`.
 */
class NormalizedSampleSource {
public:

  static constexpr double normalizationScale = double(1.0) / double(1 << 15);

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
  double operator[](size_t index) const { return samples_.at(index); }
#else
  /**
   Obtain the sample at the given index

   @param index the index to use
   @returns sample at the index
   */
  double operator[](size_t index) const { return samples_[index]; }
#endif

  /// @returns the sample header ('shdr') of the sample stream being rendered
  const Entity::SampleHeader& header() const { return header_; }

private:

  // Rudimentary testing with -O0 shows this to be 40% faster than the loop.
  void loadNormalizedSamplesAccelerated() const {
    os_signpost_id_t signpost = os_signpost_id_generate(log_);
    size_t size = header_.endIndex() - header_.startIndex();
    assert(samples_.size() == size);
    assert(!loaded_);

    os_signpost_interval_begin(log_, signpost, "loadNormalizedSamples", "begin - size: %ld", size);
    auto pos = allSamples_ + header_.startIndex();
    double scale = (1 << 15);
    vDSP_Stride stride{1};
    vDSP_vflt16D(pos, stride, samples_.data(), stride, size);
    vDSP_vsdivD(samples_.data(), stride, &scale, samples_.data(), stride, size);
    os_signpost_interval_end(log_, signpost, "loadNormalizedSamples", "end");

    // while (size-- > 0) samples_.emplace_back(*pos++ * normalizationScale);
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

    loaded_ = true;
  }

  mutable std::vector<double> samples_;
  const Entity::SampleHeader& header_;

  const int16_t* allSamples_;
  mutable bool loaded_{false};

  inline static Logger log_{Logger::Make("Render.Sample", "NormalizedSampleSource")};
};

} // namespace SF2::Render::Sample::Source
