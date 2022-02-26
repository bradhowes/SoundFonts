// Copyright © 2020 Brad Howes. All rights reserved.

#include "LowPassFilter.hpp"

using namespace SF2::Render;

enum Index { B0 = 0, B1, B2, A1, A2 };

void
LowPassFilter::update()
{
  auto cutoff = state_.modulated(State::State::Index::initialFilterCutoff);
  auto resonance = state_.modulated(State::State::Index::initialFilterResonance);

  const Float frequencyRads = DSP::PI * cutoff * nyquistPeriod_;
  const Float r = ::pow(10.0f, 0.05f * -resonance);
  const double k  = 0.5 * r * ::sin(frequencyRads);
  const double c1 = (1.0 - k) / (1.0 + k);
  const double c2 = (1.0 + c1) * ::cos(frequencyRads);
  const double c3 = (1.0 + c1 - c2) * 0.25;

  F_[B0] = c3;
  F_[B1] = c3 + c3;
  F_[B2] = c3;
  F_[A1] = -c2;
  F_[A2] = c1;

  // As long as we have the same number of channels, we can use Accelerate's function to update the filter.
  if (setup_ != nullptr) {
    vDSP_biquadm_SetTargetsDouble(setup_, F_.data(), updateRate_, threshold_, 0, 0, 1, 1);
  }
  else {
    setup_ = vDSP_biquadm_CreateSetup(F_.data(), 1, 1);
  }
}
