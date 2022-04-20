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
using Interpolator = SF2::Render::Voice::Sample::Generator::Interpolator;

@implementation SF2Engine {
  os_log_t log_;
  Engine* engine_;
  File* file_;
  NSURL* url_;
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
  }

  return self;
}

- (nullable NSURL*)url { return url_; }

- (NSString*)presetName { return [NSString stringWithUTF8String:engine_->activePresetName().c_str()]; }

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

- (void)selectBank:(int)bank program:(int)program {
  engine_->usePreset(bank, program);
}

- (int)presetCount { return static_cast<int>(engine_->presetCount()); }

- (int)voiceCount { return static_cast<int>(engine_->voiceCount()); }

- (int)activeVoiceCount { return static_cast<int>(engine_->activeVoiceCount()); }

- (void)allOff { engine_->allOff(); }

- (void)noteOff:(int)key { engine_->noteOff(key); }

- (void)noteOn:(int)key velocity:(int)velocity { engine_->noteOn(key, velocity); }

- (AUInternalRenderBlock)internalRenderBlock {
  os_log_debug(log_, "internalRenderBlock");
  auto& engine = *engine_;
  auto& log = log_;
  NSInteger bus = 0;

  return ^AUAudioUnitStatus(AudioUnitRenderActionFlags*, const AudioTimeStamp* timestamp,
                            AUAudioFrameCount frameCount, NSInteger, AudioBufferList* output,
                            const AURenderEvent* realtimeEventListHead, AURenderPullInputBlock pullInputBlock) {
    os_log_debug(log, "internalRenderBlock - calling processAndRender");
    return engine.processAndRender(timestamp, frameCount, bus, output, realtimeEventListHead, pullInputBlock);
  };
}

@end
