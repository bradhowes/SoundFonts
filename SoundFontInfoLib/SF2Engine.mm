// Copyright © 2022 Brad Howes. All rights reserved.

#import <CoreAudioKit/CoreAudioKit.h>
#import <os/log.h>

#import "SF2Engine.h"
#import "SF2Lib/Configuration.h"
#import "SF2Lib/IO/File.hpp"
#import "SF2Lib/Render/Engine/Engine.hpp"

using File = SF2::IO::File;
using Engine = SF2::Render::Engine::Engine;
using Interpolator = SF2::Render::Voice::Sample::Interpolator;

@implementation SF2Engine {
  Engine* engine_;
  NSURL* url_;
}

- (instancetype)initVoiceCount:(int)voiceCount {
  if (self = [super init]) {
    self->engine_ = new Engine(44100.0, static_cast<size_t>(voiceCount), Interpolator::cubic4thOrder);
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

  auto path = std::string([url path].UTF8String);
  auto response = engine_->load(path, 0);
  switch (response) {
    case SF2::IO::File::LoadResponse::ok: 
      url_ = url;
      return SF2EnginePresetChangeStatus_OK;
    case SF2::IO::File::LoadResponse::notFound: return SF2EnginePresetChangeStatus_FileNotFound;
    case SF2::IO::File::LoadResponse::invalidFormat: return SF2EnginePresetChangeStatus_InvalidFormat;
  }
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
