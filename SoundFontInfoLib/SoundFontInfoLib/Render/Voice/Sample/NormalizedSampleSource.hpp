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
#include "Render/Voice/Sample/Bounds.hpp"

namespace SF2::Render::Voice::Sample {

/**
 Contains a collection of audio samples that range between -1.0 and 1.0. The values are derived from the
 16-bit values found in the SF2 file. Note that this conversion is done on-demand via the first call to
 `load`.
 */
class NormalizedSampleSource {
public:

  static constexpr Float normalizationScale = Float(1.0) / Float(1 << 15);
  static constexpr size_t sizePaddingAfterEnd = 46; // SF2 spec 7.10

  /**
   Construct a new normalized buffer of samples.

   @param samples pointer to the first 16-bit sample in the SF2 file
   @param header defines the range of samples to actually load
   */
  NormalizedSampleSource(const int16_t* samples, const Entity::SampleHeader& header) :
  samples_(header.endIndex() - header.startIndex() + sizePaddingAfterEnd), header_{header}, allSamples_{samples} {}

  /**
   Load the samples into buffer if not already available.
   */
  inline void load() const { if (!loaded_) loadNormalizedSamples<Float>(); }

  /// @returns true if the buffer is loaded
  bool isLoaded() const { return loaded_; }

  /// @returns number of samples in the canonical representation
  size_t size() const { return loaded_ ? samples_.size() : 0; }

  void unload() const {
    loaded_ = false;
    samples_.clear();
  }

  /**
   Obtain the sample at the given index

   @param index the index to use
   @returns sample at the index
   */
  Float operator[](size_t index) const { return checkedVectorIndexing<decltype(samples_)>(samples_, index); }

  /// @returns the sample header ('shdr') of the sample stream being rendered
  const Entity::SampleHeader& header() const { return header_; }

  /**
   Obtain the max magnitude seen in the samples.
   */
  Float maxMagnitude() const { return loaded_ ? maxMagnitude_ : 0.0; }

  /**
   Obtain the max magnitude seen in the samples of the loop specified by the given bounds.
   */
  Float maxMagnitudeOfLoop() const { return loaded_ ? maxMagnitudeOfLoop_ : 0.0; }

private:

  template <typename T>
  void loadNormalizedSamples() const {
    assert(!loaded_);

    os_signpost_id_t signpost = os_signpost_id_generate(log_);

    const size_t startIndex = header_.startIndex();
    const size_t size = header_.endIndex() - startIndex;
    samples_.resize(size + sizePaddingAfterEnd);

    os_signpost_interval_begin(log_, signpost, "loadNormalizedSamples", "begin - size: %ld", size);
    auto pos = allSamples_ + header_.startIndex();
    constexpr T scale = (1 << 15);
    Accelerated<T>::conversionProc(pos, 1, samples_.data(), 1, size);
    Accelerated<T>::scaleProc(samples_.data(), 1, &scale, samples_.data(), 1, size);
    os_signpost_interval_end(log_, signpost, "loadNormalizedSamples", "end");

    auto bounds{Sample::Bounds::make(header_)};

    maxMagnitude_ = getMaxMagnitude<T>(0, size);
    maxMagnitudeOfLoop_ = bounds.hasLoop() ? getMaxMagnitude<T>(bounds.startLoopPos(), bounds.endLoopPos()) : 0.0;

    loaded_ = true;
  }

  template <typename T>
  T getMaxMagnitude(size_t startPos, size_t endPos) const {
    assert(endPos > startPos);
    T value{0.0};
    assert(samples_.size() > startPos && samples_.size() >= endPos);
    Accelerated<T>::magnitudeProc(samples_.data() + startPos, 1, &value, endPos - startPos);
    return value;
  }

  using SampleVector = std::vector<Float>;

  mutable SampleVector samples_;
  const Entity::SampleHeader& header_;

  const int16_t* allSamples_;
  mutable bool loaded_{false};
  mutable Float maxMagnitude_;
  mutable Float maxMagnitudeOfLoop_;

  inline static Logger log_{Logger::Make("Render", "NormalizedSampleSource")};
};

} // namespace SF2::Render::Sample::Source
