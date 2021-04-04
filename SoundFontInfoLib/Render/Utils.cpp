// Copyright © 2020 Brad Howes. All rights reserved.

#include "Utils.hpp"


//static void
//SF2::Render::Utils::buildConcaveTable()
//{
//    for(i = 1; i < FLUID_VEL_CB_SIZE - 1; i++)
//    {
//        x = (-200.0 / FLUID_PEAK_ATTENUATION) * log((double)(i * i) / ((FLUID_VEL_CB_SIZE - 1) * (FLUID_VEL_CB_SIZE - 1))) / M_LN10;
//        fluid_convex_tab[i] = (1.0 - x);
//        fluid_concave_tab[(FLUID_VEL_CB_SIZE - 1) - i] =  x;
//    }
//}
//

// FLUID_PEAK_ATTENUATION  = 960.0f

//(-200.0 / 960.0) * log((x * x) / (127 * 127)) / M_LN10;

