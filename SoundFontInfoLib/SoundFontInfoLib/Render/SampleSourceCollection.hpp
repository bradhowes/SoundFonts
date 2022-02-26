// Copyright © 2022 Brad Howes. All rights reserved.

#pragma once

#include <map>

#include "Entity/SampleHeader.hpp"
#include "Render/Voice/Sample/NormalizedSampleSource.hpp"

namespace SF2::Render {

class SampleSourceCollection
{
public:
  using SampleHeader = Entity::SampleHeader;
  using Key = uint64_t;

  void add(const SampleHeader& header, const int16_t* rawSamples)
  {
    headers_.push_back(header);
    auto key{makeKey(header)};
    auto found = collection_.find(key);
    if (found == collection_.end()) {
      auto [it, ok] = collection_.emplace(key, Voice::Sample::NormalizedSampleSource{rawSamples, header});
      if (!ok) throw std::runtime_error("failed to insert sample source");
    }
  }

  const Voice::Sample::NormalizedSampleSource& operator[](size_t index) const
  {
    if (index >= headers_.size()) throw std::runtime_error("invalid header index");
    auto found = collection_.find(makeKey(headers_[index]));
    if (found == collection_.end()) throw std::runtime_error("failed to locate sample source");
    return found->second;
  }

private:

  Key makeKey(const SampleHeader& header) const {
    return uint64_t(header.startIndex()) << 32 | header.endIndex();
  }

  std::map<Key, Voice::Sample::NormalizedSampleSource> collection_;
  std::vector<SampleHeader> headers_;
};

}
