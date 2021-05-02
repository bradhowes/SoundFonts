//
//  main.cpp
//  DSPGenerators
//
//  Created by Brad Howes on 30/4/21.
//  Copyright © 2021 Brad Howes. All rights reserved.
//

#include <fstream>
#include <iostream>

#include "DSPGenerators.hpp"

int main(int argc, const char * argv[]) {
    auto os = std::ofstream(argv[1]);
    SF2::DSP::Tables::Generator generator{os};
    os.flush();
    os.close();
    return 0;
}
