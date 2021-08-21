// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <os/log.h>
#include <os/signpost.h>
#include <AudioToolbox/AUParameters.h>
#include <vector>

#include "Logger.hpp"
#include "DSP/DSP.hpp"
#include "Entity/SampleHeader.hpp"

namespace SF2::Render::Sample {

/**
 Contains a collection of audio samples that range between -1.0 and 1.0. The values are derived from the
 16-bit values found in the SF2 file. Note that this conversion is done on-demand via the first call to
 `load`.
 */
class CanonicalBuffer {
public:

  /**
   Construct a new normalized buffer of samples.

   @param samples pointer to the first 16-bit sample in the SF2 file
   @param header defines the range of samples to use for a sound
   */
  CanonicalBuffer(const int16_t* samples, const Entity::SampleHeader& header) :
  samples_{}, header_{header}, allSamples_{samples} {}

  /**
   Load the samples into buffer if not already available.
   */
  inline void load() const { if (samples_.empty()) loadNormalizedSamples(); }

  /// @returns true if the buffer is loaded
  bool isLoaded() const { return !samples_.empty(); }

  /// @returns number of samples in the canonical representation
  size_t size() const { return samples_.size(); }

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

  void loadNormalizedSamples() const {
    static constexpr double scale = double(1.0) / double(1 << 15);
    os_signpost_id_t signpost = os_signpost_id_generate(log_);
    size_t size = header_.endIndex() - header_.startIndex();

    os_signpost_interval_begin(log_, signpost, "loadNormalizedSamples", "begin - size: %ld", size);
    samples_.reserve(size);
    samples_.clear();
    auto pos = allSamples_ + header_.startIndex();
    while (size-- > 0) samples_.emplace_back(*pos++ * scale);
    os_signpost_interval_end(log_, signpost, "loadNormalizedSamples", "end");
  }

  mutable std::vector<double> samples_;
  const Entity::SampleHeader& header_;
  const int16_t* allSamples_;
  inline static Logger log_{Logger::Make("Render.Sample", "CanonicalBuffer")};
};

} // namespace SF2::Render::Sample::Source
