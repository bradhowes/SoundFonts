// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <iostream>
#include <Accelerate/../Frameworks/vecLib.framework/Headers/vForce.h>

#include "DSP/DSP.hpp"
#include "Entity/SampleHeader.hpp"
#include "Render/LFO.hpp"
#include "Render/Voice/State/State.hpp"

namespace SF2::Render {

class LowPassFilter
{
public:
  using State = Voice::State::State;

  LowPassFilter(const State& state) : state_{state}, nyquistPeriod_{1.0f / Float(0.5f * state.sampleRate())} {}

  void setSampleRate(Float sampleRate) {
    nyquistPeriod_ = 1.0f / Float(0.5f * sampleRate);
    update();
  }

  void update();

  void apply(std::vector<Float*> const& ins, std::vector<Float*>& outs, size_t frameCount) const
  {
    assert(ins.size() == outs.size() && ins.size() == 2);
    vDSP_biquadm(setup_, (float const**)ins.data(), vDSP_Stride(1), (float**)outs.data(), vDSP_Stride(1),
                 vDSP_Length(frameCount));
  }

private:
  
  const State& state_;
  Float nyquistPeriod_;

  std::array<double, 5> F_{0.0};
  vDSP_biquadm_Setup setup_{nullptr};

  Float lastCutoff_{-1.0};
  Float lastResonance_{1E10};

  float threshold_{0.05f};
  float updateRate_{0.4f};
};

} // namespace SF2::Render
