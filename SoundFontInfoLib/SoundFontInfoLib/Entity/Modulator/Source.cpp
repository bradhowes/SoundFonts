// Copyright © 2020 Brad Howes. All rights reserved.

#include <cmath>
#include <iostream>
#include <sstream>

#include "Source.hpp"

using namespace SF2::Entity::Modulator;

std::string
Source::description() const {
    std::ostringstream os;
    if (isGeneralController()) {
        switch (generalIndex()) {
            case GeneralIndex::none: os << "none"; break;
            case GeneralIndex::noteOnVelocity: os << "velocity"; break;
            case GeneralIndex::noteOnKeyValue: os << "key"; break;
            case GeneralIndex::polyPressure: os << "polyPressure"; break;
            case GeneralIndex::channelPressure: os << "channelPressure"; break;
            case GeneralIndex::pitchWheel: os << "pitchWheel"; break;
            case GeneralIndex::pitchWheelSensitivity: os << "pitchWheelSensitivity"; break;
            case GeneralIndex::link: os << "link"; break;
        }
    }
    else if (isContinuousController()) {
        os << "CC[" << continuousIndex() << ']';
    }
    else {
        os << "*INVALID*";
    }

    os << '(' << (isUnipolar() ? "uni" : "bi") << '/' << (isMinToMax() ? "-+" : "+-") << '/'
    << continuityTypeName() << ')';

    return os.str();
}

namespace SF2 {
namespace Entity {
namespace Modulator {

std::ostream&
operator<<(std::ostream& os, const Source& mod)
{
    return os << mod.description();
}

}
}
}
