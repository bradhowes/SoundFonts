// Copyright © 2021 Brad Howes. All rights reserved.

#pragma once

#include <cmath>
#include <vector>

namespace SF2 {
namespace Render {

template <typename T>
class DelayBuffer {
public:
    DelayBuffer(double sizeInSamples)
    : wrapMask_{smallestPowerOf2For(sizeInSamples) - 1}, buffer_(wrapMask_ + 1, 0.0), writePos_{0}
    {
        clear();
    }

    void clear() { std::fill(buffer_.begin(), buffer_.end(), 0.0); }

    void setSizeInSamples(double sizeInSamples) {
        wrapMask_ = smallestPowerOf2For(sizeInSamples) - 1;
        buffer_.resize(wrapMask_ + 1);
        writePos_ = 0;
        clear();
    }

    void write(T value) {
        buffer_[writePos_] = value;
        writePos_ = (writePos_ + 1) & wrapMask_;
    }

    size_t size() const { return buffer_.size(); }

    T readFromOffset(int offset) const { return buffer_[(writePos_ - offset) & wrapMask_]; }

    T read(double delay) const {
        auto offset = int(delay);
        T y1 = readFromOffset(offset);
        T y2 = readFromOffset(offset + 1);
        auto partial = delay - offset;
        assert(partial >= 0.0 && partial < 1.0);
        return y2 * partial + (1.0 - partial) * y1;
    }

private:

    static size_t smallestPowerOf2For(double value) {
        return size_t(std::pow(2.0, std::ceil(std::log2(std::fmaxf(value, 1.0)))));
    }

    size_t wrapMask_;
    std::vector<T> buffer_;
    size_t writePos_;
};

} // namespace Render
} // namespace SF2
