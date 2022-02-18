// Copyright © 2021 Brad Howes. All rights reserved.
//

#pragma once

typedef double fluid_real_t;

// Used to compare our own routines with those from FluidSynth
extern fluid_real_t fluid_ct2hz_real(fluid_real_t cents);

// Not used as I think FluidSynth table generation is incorrect (1 too many values in lookup table).
extern fluid_real_t fluid_pan(fluid_real_t c, int left);
