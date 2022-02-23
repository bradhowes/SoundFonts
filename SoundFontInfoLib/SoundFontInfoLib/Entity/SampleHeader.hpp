// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "Types.hpp"
#include "IO/Pos.hpp"
#include "IO/StringUtils.hpp"

namespace SF2::Entity {

/**
 Define the audio samples to be used for playing a specific sound.
 
 Memory layout of a 'shdr' entry. The size of this is defined to be 46 bytes, but due
 to alignment/padding the struct below is 48 bytes.
 
 The offsets (begin, end, loopBegin, and loopEnd) are indices into a big array of 16-bit integer sample values.

 From the SF2 spec:

 The values of dwStart, dwEnd, dwStartloop, and dwEndloop must all be within the range of the sample data field
 included in the SoundFont compatible bank or referenced in the sound ROM. Also, to allow a variety of hardware
 platforms to be able to reproduce the data, the samples have a minimum length of 48 data points, a minimum loop size
 of 32 data points and a minimum of 8 valid points prior to dwStartloop and after dwEndloop. Thus dwStart must be less
 than dwStartloop-7,

 dwStartloop must be less than dwEndloop-31, and dwEndloop must be less than dwEnd-7. If these constraints are not met,
 the sound may optionally not be played if the hardware cannot support artifact-free playback for the parameters given.
 */
class SampleHeader {
public:
  constexpr static size_t size = 46;
  
  enum Type {
    monoSample = 1,
    rightSample = 2,
    leftSample = 4,
    linkedSample = 8,
    rom = 0x8000
  };
  
  /**
   Construct new instance from SF2 file
   */
  explicit SampleHeader(IO::Pos& pos)
  {
    assert(sizeof(*this) == size + 2);
    // Account for the extra padding by reading twice.
    pos = pos.readInto(&achSampleName, 40);
    pos = pos.readInto(&originalKey, 6);
    IO::trim_property(achSampleName);
  }
  
  /**
   Construct instance for unit tests.
   */
  SampleHeader(uint32_t start, uint32_t end, uint32_t loopBegin, uint32_t loopEnd,
               uint32_t sampleRate, uint8_t key, int8_t adjustment) :
  dwStart{start}, dwEnd{end}, dwStartLoop{loopBegin}, dwEndLoop{loopEnd}, dwSampleRate{sampleRate}, originalKey{key},
  correction{adjustment} {}
  
  /// @returns true if this sample only has one channel
  bool isMono() const { return (sampleType & monoSample) == monoSample; }
  
  /// @returns true if these samples generate for the right channel
  bool isRight() const { return (sampleType & rightSample) == rightSample; }
  
  /// @returns true if these samples generate for the left channel
  bool isLeft() const { return (sampleType & leftSample) == leftSample; }
  
  /// @returns true if samples come from a ROM
  bool isROM() const { return (sampleType & rom) == rom; }

  const char* sampleName() const { return achSampleName; }

  bool hasLoop() const { return dwStartLoop > dwStart && dwStartLoop < dwEndLoop && dwEndLoop <= dwEnd; }

  /**
   The DWORD dwStart contains the index, in sample data points, from the beginning of the sample data field to the
   first data point of this sample.

   @returns the index of the first sample to use
   */
  size_t startIndex() const { return dwStart; }
  
  /**
   The DWORD dwEnd contains the index, in sample data points, from the beginning of the sample data field to the first
   of the set of 46 zero valued data points following this sample.

   @returns index + 1 of the last sample to use.
   */
  size_t endIndex() const { return dwEnd; }

  /**
   The DWORD dwStartloop contains the index, in sample data points, from the beginning of the sample data field to the
   first data point in the loop of this sample.

   @returns index of the first sample in a loop.
   */
  size_t startLoopIndex() const { return dwStartLoop; }

  /**
   The DWORD dwEndloop contains the index, in sample data points, from the beginning of the sample data field to the
   first data point following the loop of this sample. Note that this is the data point “equivalent to” the first loop
   data point, and that to produce portable artifact free loops, the eight proximal data points surrounding both the
   Startloop and Endloop points should be identical.

   @returns index of the last + 1 of a sample in a loop.
   */
  size_t endLoopIndex() const { return dwEndLoop; }
  
  /// @returns the sample rate used to record the samples in the SF2 file
  size_t sampleRate() const { return dwSampleRate; }
  
  /// @returns the MIDI key (frequency) for the source samples
  int originalMIDIKey() const { return originalKey; }
  
  /// @returns the pitch correction to apply when playing back the samples
  int pitchCorrection() const { return correction; }

  size_t sampleSize() const { return endIndex() - startIndex(); }
  
  void dump(const std::string& indent, size_t index) const;

private:
  std::string sampleTypeDescription() const;
  
  char achSampleName[20];
  uint32_t dwStart;
  uint32_t dwEnd;
  uint32_t dwStartLoop;
  uint32_t dwEndLoop;
  uint32_t dwSampleRate;
  // *** PADDING ***
  uint8_t originalKey;
  int8_t correction;
  uint16_t sampleLink;
  uint16_t sampleType;
};

} // end namespace SF2::Entity
