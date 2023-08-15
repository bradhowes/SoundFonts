// Copyright © 2022 Brad Howes. All rights reserved.

#import <CoreAudioKit/CoreAudioKit.h>
#import <os/log.h>

#import "SF2Engine.h"
#import "SF2Lib/Configuration.h"
#import "SF2Lib/IO/File.hpp"
#import "SF2Lib/IO/Format.hpp"
#import "SF2Lib/Render/Engine/Engine.hpp"

using File = SF2::IO::File;
using Engine = SF2::Render::Engine::Engine;
using Interpolator = SF2::Render::Voice::Sample::Interpolator;

@implementation SF2Engine {
  Engine* engine_;
  File* file_;
  NSURL* url_;
}

- (instancetype)initVoiceCount:(int)voiceCount {
  if (self = [super init]) {
    self->engine_ = new Engine(44100.0, static_cast<size_t>(voiceCount), Interpolator::cubic4thOrder);
    self->file_ = nullptr;
    self->url_ = nullptr;
  }

  return self;
}

- (nullable NSURL*)url { return url_; }

- (NSString*)presetName { return [NSString stringWithUTF8String:engine_->activePresetName().c_str()]; }

- (void)setRenderingFormat:(NSInteger)busCount format:(AVAudioFormat*)format
         maxFramesToRender:(AUAudioFrameCount)maxFramesToRender {
  engine_->setRenderingFormat(busCount, format, maxFramesToRender);
}

- (void)renderingStopped {
  engine_->allOff();
}

- (SF2EnginePresetChangeStatus)load:(NSURL*)url {
  engine_->allOff();
  if ([url_ isEqual:url]) return SF2EnginePresetChangeStatus_OK;

  url_ = url;
  auto oldFile = file_;
  try {
    file_ = new File([[url path] UTF8String]);
    engine_->load(*file_, 0);
  } catch (std::runtime_error&) {
    if (oldFile != nullptr) file_ = oldFile;
    return SF2EnginePresetChangeStatus_FileNotFound;
  } catch (SF2::IO::Format&) {
    if (oldFile != nullptr) file_ = oldFile;
    return SF2EnginePresetChangeStatus_CannotAccessFile;
  }

  delete oldFile;
  return SF2EnginePresetChangeStatus_OK;
}

- (SF2EnginePresetChangeStatus)selectPreset:(int)index {
  if (index < 0 || index >= int(engine_->presetCount())) return SF2EnginePresetChangeStatus_InvalidIndex;
  engine_->usePreset(size_t(index));
  return SF2EnginePresetChangeStatus_OK;
}

- (void)selectBank:(uint16_t)bank program:(uint16_t)program {
  engine_->usePreset(bank, program);
}

- (int)presetCount { return static_cast<int>(engine_->presetCount()); }

- (int)voiceCount { return static_cast<int>(engine_->voiceCount()); }

- (int)activeVoiceCount { return static_cast<int>(engine_->activeVoiceCount()); }

- (void)stopAllNotes { engine_->allOff(); }

- (void)stopNote:(UInt8)key velocity:(UInt8)velocity { engine_->noteOff(key); }

- (void)startNote:(UInt8)key velocity:(UInt8)velocity { engine_->noteOn(key, velocity); }

- (AUInternalRenderBlock)internalRenderBlock {
  auto& engine = *engine_;
  NSInteger bus = 0;

  return ^AUAudioUnitStatus(AudioUnitRenderActionFlags*, const AudioTimeStamp* timestamp,
                            AUAudioFrameCount frameCount, NSInteger, AudioBufferList* output,
                            const AURenderEvent* realtimeEventListHead, AURenderPullInputBlock pullInputBlock) {
    return engine.processAndRender(timestamp, frameCount, bus, output, realtimeEventListHead, pullInputBlock);
  };
}

@end
