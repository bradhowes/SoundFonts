// Copyright © 2022 Brad Howes. All rights reserved.

#import <CoreAudioKit/CoreAudioKit.h>
#import <os/log.h>

#import "SF2Engine.h"
#import "SF2Lib/Configuration.h"
#import "SF2Lib/IO/File.hpp"
#import "SF2Lib/Render/Engine/Engine.hpp"

using File = SF2::IO::File;
using Engine = SF2::Render::Engine::Engine;
using Interpolator = SF2::Render::Voice::Sample::Generator::Interpolator;

@implementation SF2Engine {
  os_log_t log_;
  Engine* engine_;
  File* file_;
  NSURL* url_;
  NSString* shortName_;
}

- (instancetype)initLoggingBase:(NSString*)loggingBase voiceCount:(int)voicesCount {
  if (self = [super init]) {
    self->log_ = os_log_create([loggingBase UTF8String], "SF2Engine");
    loggingBase = [loggingBase stringByAppendingString:@".SF2Engine"];
    os_log_info(log_, "init");
    self->engine_ = new Engine([loggingBase UTF8String], 44100.0, static_cast<size_t>(voicesCount),
                               Interpolator::cubic4thOrder);
    self->file_ = nullptr;
    self->url_ = nullptr;
    self->shortName_ = nullptr;
  }

  return self;
}

- (nullable NSURL*) url { return url_; }

- (nullable NSString*) shortName { return shortName_; }

- (void)setRenderingFormat:(NSInteger)busCount format:(AVAudioFormat*)format
         maxFramesToRender:(AUAudioFrameCount)maxFramesToRender {
  os_log_info(log_, "setRenderingFormat BEGIN");
  engine_->setRenderingFormat(busCount, format, maxFramesToRender);
  os_log_info(log_, "setRenderingFormat END");
}

- (void)renderingStopped {
  os_log_info(log_, "renderingStopped BEGIN");
  engine_->allOff();
  os_log_info(log_, "renderingStopped END");
}

- (void)load:(NSURL*)url preset:(int)index shortName:(nonnull NSString *)shortName{
  engine_->allOff();

  shortName_ = shortName;
  if ([url_ isEqual:url]) {
    engine_->usePreset(static_cast<size_t>(index));
    return;
  }

  url_ = url;
  auto oldFile = file_;
  file_ = new File([[url path] UTF8String]);
  engine_->load(*file_, static_cast<size_t>(index));
  delete oldFile;
}

- (void)selectBank:(int)bank program:(int)program {
  // engine_->usePreset(static_cast<size_t>(preset));
}

- (int)presetCount { return static_cast<int>(engine_->presetCount()); }

- (int)voiceCount { return static_cast<int>(engine_->voiceCount()); }

- (int)activeVoiceCount { return static_cast<int>(engine_->activeVoiceCount()); }

- (void)allOff { engine_->allOff(); }

- (void)noteOff:(int)key { engine_->noteOff(key); }

- (void)noteOn:(int)key velocity:(int)velocity { engine_->noteOn(key, velocity); }

- (AUInternalRenderBlock)internalRenderBlock {
  os_log_info(log_, "internalRenderBlock");
  auto& engine = *engine_;
  auto& log = log_;
  NSInteger bus = 0;

  return ^AUAudioUnitStatus(AudioUnitRenderActionFlags*, const AudioTimeStamp* timestamp,
                            AUAudioFrameCount frameCount, NSInteger, AudioBufferList* output,
                            const AURenderEvent* realtimeEventListHead, AURenderPullInputBlock pullInputBlock) {
    os_log_info(log, "internalRenderBlock - calling processAndRender");
    return engine.processAndRender(timestamp, frameCount, bus, output, realtimeEventListHead, pullInputBlock);
  };
}

@end
