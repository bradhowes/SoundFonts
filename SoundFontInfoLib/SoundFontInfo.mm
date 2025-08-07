// Copyright © 2020 Brad Howes. All rights reserved.

#include "SF2File/IO/Parser.hpp"
#include "SF2File/IO/File.hpp"

#include "SoundFontInfo.h"

using namespace SF2;

@implementation SoundFontInfoPreset

- (id)initForPresetInfo:(IO::Parser::PresetInfo const &)preset {
  if (self = [super init]) {
    self.name = [NSString stringWithUTF8String:preset.name.c_str()];
    self.bank = preset.bank;
    self.program = preset.preset;
  }
  
  return self;
}

- (id)initForSFPreset:(Entity::Preset const &)preset {
  if (self = [super init]) {
    self.name = [NSString stringWithUTF8String:preset.cname()];
    self.bank = preset.bank();
    self.program = preset.program();
  }
  
  return self;
}

- (id)init:(NSString*)name bank:(int)bank program:(int)program {
  if (self = [super init]) {
    self.name = name;
    self.bank = bank;
    self.program = program;
  }
  
  return self;
}

@end

@implementation SoundFontInfo

- (id)init:(NSString*)name url:(NSURL*)url
    author:(NSString*)embeddedAuthor
   comment:(NSString*)embeddedComment
 copyright:(NSString*)embeddedCopyright
   presets:(NSArray<SoundFontInfoPreset*>*)presets
{
  if (self = [super init]) {
    self.url = url;
    self.embeddedName = name;
    self.embeddedAuthor = embeddedAuthor;
    self.embeddedComment = embeddedComment;
    self.embeddedCopyright = embeddedCopyright;
    self.presets = presets;
  }
  return self;
}

+ (SoundFontInfo*)loadViaParser:(NSURL*)url {
  try {
    BOOL secured = [url startAccessingSecurityScopedResource];
    SoundFontInfo* info = [SoundFontInfo parseViaParser:url];
    if (secured) [url stopAccessingSecurityScopedResource];
    return info;
  }
  catch (enum IO::File::LoadResponse value) {
    return nil;
  }
}

+ (SoundFontInfo*)loadViaFile:(NSURL*)url {
  try {
    BOOL secured = [url startAccessingSecurityScopedResource];
    SoundFontInfo* info = [SoundFontInfo parseViaFile:url];
    if (secured) [url stopAccessingSecurityScopedResource];
    return info;
  }
  catch (enum IO::File::LoadResponse value) {
    return nil;
  }
}

+ (SoundFontInfo*)parseViaFile:(NSURL*)url {
  SoundFontInfo* result = nil;
  try {
    auto info = IO::File(url.path.UTF8String);

    NSString* embeddedName = [NSString stringWithUTF8String:info.embeddedName().c_str()];
    NSString* embeddedAuthor = [NSString stringWithUTF8String:info.embeddedAuthor().c_str()];
    NSString* embeddedCopyright = [NSString stringWithUTF8String:info.embeddedCopyright().c_str()];
    NSString* embeddedComment = [NSString stringWithUTF8String:info.embeddedComment().c_str()];

    NSMutableArray* presets = [NSMutableArray arrayWithCapacity:info.presets().size()];
    for (const auto& preset : info.presets()) {
      [presets addObject:[[SoundFontInfoPreset alloc] initForSFPreset:preset]];
    }

    [presets sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
      SoundFontInfoPreset* patch1 = obj1;
      SoundFontInfoPreset* patch2 = obj2;
      if (patch1.bank < patch2.bank) return NSOrderedAscending;
      if (patch1.bank > patch2.bank) return NSOrderedDescending;
      if (patch1.program < patch2.program) return NSOrderedAscending;
      if (patch1.program == patch2.program) return NSOrderedSame;
      return NSOrderedDescending;
    }];
    
    result = [[SoundFontInfo alloc] init:embeddedName
                                     url:url
                                  author:embeddedAuthor
                                 comment:embeddedComment
                               copyright:embeddedCopyright
                                 presets:presets];
  }
  catch (enum IO::File::LoadResponse value) {
    ;
  }
  
  return result;
}

+ (SoundFontInfo*)parseViaParser:(NSURL*)url {
  SoundFontInfo* result = nil;
  try {
    auto info = IO::Parser::parse(url.path.UTF8String);

    NSString* embeddedName = [NSString stringWithUTF8String:info.embeddedName.c_str()];
    NSString* embeddedAuthor = [NSString stringWithUTF8String:info.embeddedAuthor.c_str()];
    NSString* embeddedCopyright = [NSString stringWithUTF8String:info.embeddedCopyright.c_str()];
    NSString* embeddedComment = [NSString stringWithUTF8String:info.embeddedComment.c_str()];
    NSMutableArray* presets = [NSMutableArray arrayWithCapacity:info.presets.size()];
    
    for (auto it = info.presets.begin(); it != info.presets.end(); ++it) {
      [presets addObject:[[SoundFontInfoPreset alloc] initForPresetInfo:*it]];
    }
    
    [presets sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
      SoundFontInfoPreset* patch1 = obj1;
      SoundFontInfoPreset* patch2 = obj2;
      if (patch1.bank < patch2.bank) return NSOrderedAscending;
      if (patch1.bank > patch2.bank) return NSOrderedDescending;
      if (patch1.program < patch2.program) return NSOrderedAscending;
      if (patch1.program == patch2.program) return NSOrderedSame;
      return NSOrderedDescending;
    }];
    
    result = [[SoundFontInfo alloc] init:embeddedName
                                     url:url
                                  author:embeddedAuthor
                                 comment:embeddedComment
                               copyright:embeddedCopyright
                                 presets:presets];
  }
  catch (enum IO::File::LoadResponse value) {
    ;
  }
  
  return result;
}

@end
