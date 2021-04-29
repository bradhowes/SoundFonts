// Copyright © 2020 Brad Howes. All rights reserved.

#include <cmath>

#include "Render/DSP.hpp"
#include "ValueTransformer.hpp"

using namespace SF2::MIDI;

ValueTransformer::ValueTransformer(Kind kind, Direction direction, Polarity polarity)
: active_{selectActive(kind, direction, polarity)}
{}

// Calculate log10((127 - index)/127) to use in positiveConcave_ below (last value is log10(0.5/127)
static ValueTransformer::TransformArrayType const log10Lookup = [] {
    ValueTransformer::TransformArrayType init{};
    init[0] = 0.0;
    init[1] = -0.0034331758383939577;
    init[2] = -0.006893707947900438;
    init[3] = -0.010382035793721775;
    init[4] = -0.013898609516558956;
    init[5] = -0.017443890281208654;
    init[6] = -0.021018350639506796;
    init[7] = -0.024622474908332043;
    init[8] = -0.028256759563426104;
    init[9] = -0.03192171364983147;
    init[10] = -0.035617859209795204;
    init[11] = -0.039345731729038366;
    init[12] = -0.04310588060234521;
    init[13] = -0.04689886961948429;
    init[14] = -0.050725277472537154;
    init[15] = -0.05458569828577526;
    init[16] = -0.05848074216929943;
    init[17] = -0.062411035797731815;
    init[18] = -0.06637722301533322;
    init[19] = -0.07037996546900714;
    init[20] = -0.07441994327074725;
    init[21] = -0.07849785569118664;
    init[22] = -0.08261442188601881;
    init[23] = -0.08677038165717652;
    init[24] = -0.09096649625078465;
    init[25] = -0.0952035491940393;
    init[26] = -0.09948234717331428;
    init[27] = -0.10380372095595684;
    init[28] = -0.10816852635840697;
    init[29] = -0.11257764526346203;
    init[30] = -0.11703198668971203;
    init[31] = -0.12153248791638846;
    init[32] = -0.12608011566710908;
    init[33] = -0.1306758673562582;
    init[34] = -0.13532077240202173;
    init[35] = -0.14001589361040157;
    init[36] = -0.1447623286348633;
    init[37] = -0.14956121151663201;
    init[38] = -0.1544137143110441;
    init[39] = -0.15932104880578823;
    init[40] = -0.16428446833733834;
    init[41] = -0.16930526971238913;
    init[42] = -0.17438479524166411;
    init[43] = -0.17952443489407519;
    init[44] = -0.184725628579883;
    init[45] = -0.1899898685722402;
    init[46] = -0.19531870207730714;
    init[47] = -0.2007137339640133;
    init[48] = -0.20617662966551542;
    init[49] = -0.21170911826547645;
    init[50] = -0.21731299578347496;
    init[51] = -0.2229901286751655;
    init[52] = -0.22874245756425685;
    init[53] = -0.2345720012249807;
    init[54] = -0.240480860835501;
    init[55] = -0.24647122452468842;
    init[56] = -0.25254537223688156;
    init[57] = -0.25870568094170004;
    init[58] = -0.2649546302187015;
    init[59] = -0.2712948082497205;
    init[60] = -0.27772891825513046;
    init[61] = -0.2842597854140882;
    init[62] = -0.29089036431310134;
    init[63] = -0.2976237469720697;
    init[64] = -0.3044631715023752;
    init[65] = -0.31141203145770296;
    init[66] = -0.3184738859451898;
    init[67] = -0.3256524705723132;
    init[68] = -0.3329517093138127;
    init[69] = -0.3403757273930196;
    init[70] = -0.3479288652834655;
    init[71] = -0.35561569394975645;
    init[72] = -0.363441031461713;
    init[73] = -0.37140996113298835;
    init[74] = -0.37952785135516787;
    init[75] = -0.3878003773211577;
    init[76] = -0.3962335448580205;
    init[77] = -0.40483371661993806;
    init[78] = -0.41360764092744323;
    init[79] = -0.42256248358036963;
    init[80] = -0.4317058630202394;
    init[81] = -0.44104588927438276;
    init[82] = -0.4505912071806132;
    init[83] = -0.46035104446976943;
    init[84] = -0.4703352653763703;
    init[85] = -0.48055443055805636;
    init[86] = -0.4910198642362214;
    init[87] = -0.5017437296279945;
    init[88] = -0.5127391139294576;
    init[89] = -0.5240201243391467;
    init[90] = -0.5356019968889619;
    init[91] = -0.5475012201886696;
    init[92] = -0.5597356766056812;
    init[93] = -0.5723248039137017;
    init[94] = -0.5852897810780694;
    init[95] = -0.5986537426360509;
    init[96] = -0.6124420271216842;
    init[97] = -0.6266824662362944;
    init[98] = -0.6414057230570007;
    init[99] = -0.6566456896137377;
    init[100] = -0.6724399567969696;
    init[101] = -0.6888303729851389;
    init[102] = -0.7058637122839192;
    init[103] = -0.7235924792443509;
    init[104] = -0.742075884938364;
    init[105] = -0.7613810401337506;
    init[106] = -0.7815844262220376;
    init[107] = -0.8027737252919757;
    init[108] = -0.8250501200031278;
    init[109] = -0.8485312158526508;
    init[110] = -0.8733547995776829;
    init[111] = -0.8996837383000321;
    init[112] = -0.9277124619002757;
    init[113] = -0.9576756852777188;
    init[114] = -0.9898603686491201;
    init[115] = -1.0246224749083321;
    init[116] = -1.0624110357977319;
    init[117] = -1.1038037209559568;
    init[118] = -1.149561211516632;
    init[119] = -1.2007137339640133;
    init[120] = -1.2587056809417;
    init[121] = -1.3256524705723132;
    init[122] = -1.404833716619938;
    init[123] = -1.5017437296279945;
    init[124] = -1.6266824662362944;
    init[125] = -1.8027737252919758;
    init[126] = -2.103803720955957;
    init[127] = -2.404833716619938;
    return init;
}();

// unipolar ranges

ValueTransformer::TransformArrayType const ValueTransformer::positiveLinear_ = [] {
    TransformArrayType init{};
    for (auto index = 0; index < init.size(); ++index) {
        init[index] = double(index) / init.size();
    }
    return init;
}();

ValueTransformer::TransformArrayType const ValueTransformer::negativeLinear_ = [] {
    TransformArrayType init{};
    for (auto index = 0; index < init.size(); ++index) {
        init[index] = 1.0 - double(index) / init.size();
    }
    return init;
}();

ValueTransformer::TransformArrayType const ValueTransformer::positiveConcave_ = [] {
    TransformArrayType init{};
    for (auto index = 0; index < init.size(); ++index) {
        init[index] = -40.0 / 96.0 * log10Lookup[index];
    }
    init[init.size() - 1] = 1.0;
    return init;
}();

ValueTransformer::TransformArrayType const ValueTransformer::negativeConcave_ = [] {
    TransformArrayType init{};
    init[0] = 1.0;
    for (auto index = 1; index < init.size(); ++index) {
        init[index] = positiveConcave_[127 - index]; // -40.0 / 96.0 * log10Lookup_[127 - index];
    }
    return init;
}();

ValueTransformer::TransformArrayType const ValueTransformer::positiveConvex_ = [] {
    TransformArrayType init{};
    for (auto index = 0; index < init.size(); ++index) {
        init[index] = 1.0 - negativeConcave_[index];
    }
    return init;
}();

ValueTransformer::TransformArrayType const ValueTransformer::negativeConvex_ = [] {
    TransformArrayType init{};
    for (auto index = 0; index < init.size(); ++index) {
        init[index] = 1.0 - positiveConcave_[index];
    }
    return init;
}();

ValueTransformer::TransformArrayType const ValueTransformer::positiveSwitched_ = [] {
    TransformArrayType init{};
    // size_t index = 0;
    // while (index < init.size() / 2.0) init[index++] = 0.0;
    size_t index = init.size() / 2.0;
    while (index < init.size()) init[index++] = 1.0;
    return init;
}();

ValueTransformer::TransformArrayType const ValueTransformer::negativeSwitched_ = [] {
    TransformArrayType init{};
    size_t index = 0;
    while (index < init.size() / 2.0) init[index++] = 1.0;
    // while (index < init.size()) init[index++] = 0.0;
    return init;
}();

// bipolar ranges

ValueTransformer::TransformArrayType const ValueTransformer::positiveLinearBipolar_ = [] {
    TransformArrayType init{};
    for (auto index = 0; index < init.size(); ++index) {
        init[index] = 2.0 * positiveLinear_[index] - 1.0;
    }
    return init;
}();

ValueTransformer::TransformArrayType const ValueTransformer::negativeLinearBipolar_ = [] {
    TransformArrayType init{};
    for (auto index = 0; index < init.size(); ++index) {
        init[index] = 2.0 * negativeLinear_[index] - 1.0;
    }
    return init;
}();

ValueTransformer::TransformArrayType const ValueTransformer::positiveConcaveBipolar_ = [] {
    TransformArrayType init{};
    for (auto index = 0; index < init.size(); ++index) {
        init[index] = 2.0 * positiveConcave_[index] - 1.0;
    }
    return init;
}();

ValueTransformer::TransformArrayType const ValueTransformer::negativeConcaveBipolar_ = [] {
    TransformArrayType init{};
    for (auto index = 0; index < init.size(); ++index) {
        init[index] = 2.0 * negativeConcave_[index] - 1.0;
    }
    return init;
}();

ValueTransformer::TransformArrayType const ValueTransformer::positiveConvexBipolar_ = [] {
    TransformArrayType init{};
    for (auto index = 0; index < init.size(); ++index) {
        init[index] = 2.0 * positiveConvex_[index] - 1.0;
    }
    return init;
}();

ValueTransformer::TransformArrayType const ValueTransformer::negativeConvexBipolar_ = [] {
    TransformArrayType init{};
    for (auto index = 0; index < init.size(); ++index) {
        init[index] = 2.0 * negativeConvex_[index] - 1.0;
    }
    return init;
}();

ValueTransformer::TransformArrayType const ValueTransformer::positiveSwitchedBipolar_ = [] {
    TransformArrayType init{};
    size_t index = 0;
    while (index < init.size() / 2.0) init[index++] = -1.0;
    while (index < init.size()) init[index++] = 1.0;
    return init;
}();

ValueTransformer::TransformArrayType const ValueTransformer::negativeSwitchedBipolar_ = [] {
    TransformArrayType init{};
    size_t index = 0;
    while (index < init.size() / 2.0) init[index++] = 1.0;
    while (index < init.size()) init[index++] = -1.0;
    return init;
}();

const ValueTransformer::TransformArrayType& ValueTransformer::selectActive(Kind kind, Direction direction,
                                                                           Polarity polarity) {
    if (polarity == Polarity::unipolar) {
        switch (kind) {
            case Kind::linear:
                return direction == Direction::ascending ? positiveLinear_ : negativeLinear_;
                break;
            case Kind::concave:
                return direction == Direction::ascending ? positiveConcave_ : negativeConcave_;
                break;
            case Kind::convex:
                return direction == Direction::ascending ? positiveConvex_ : negativeConvex_;
                break;
            case Kind::switched:
                return direction == Direction::ascending ? positiveSwitched_ : negativeSwitched_;
                break;
        }
    }
    else {
        switch (kind) {
            case Kind::linear:
                return direction == Direction::ascending ? positiveLinearBipolar_ : negativeLinearBipolar_;
                break;
            case Kind::concave:
                return direction == Direction::ascending ? positiveConcaveBipolar_ : negativeConcaveBipolar_;
                break;
            case Kind::convex:
                return direction == Direction::ascending ? positiveConvexBipolar_ : negativeConvexBipolar_;
                break;
            case Kind::switched:
                return direction == Direction::ascending ? positiveSwitchedBipolar_ : negativeSwitchedBipolar_;
                break;
        }
    }
}
