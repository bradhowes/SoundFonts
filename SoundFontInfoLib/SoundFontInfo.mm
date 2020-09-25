// Copyright © 2020 Brad Howes. All rights reserved.

#include <algorithm>
#include <fstream>
#include <iostream>
#include <vector>
#include <string>

#include "Parser.hpp"
#include "SFFile.hpp"
#include "SFManager.hpp"
#include "SoundFontInfo.h"

using namespace SF2;

@implementation SoundFontInfoPreset

- (id)init:(Parser::Preset const &)preset {
    if (self = [super init]) {
        self.name = [NSString stringWithUTF8String:preset.name.c_str()];
        self.bank = preset.bank;
        self.preset = preset.preset;
    }

    return self;
}

- (id)init:(NSString*)name bank:(int)bank preset:(int)preset {
    if (self = [super init]) {
        self.name = name;
        self.bank = bank;
        self.preset = preset;
    }

    return self;
}

@end

@implementation SoundFontInfo

- (id)init:(NSString*)name url:(NSURL*)url presets:(NSArray<SoundFontInfoPreset*>*)presets {
    if (self = [super init]) {
        self.path = url;
        self.embeddedName = name;
        self.presets = presets;
    }
    return self;
}

+ (SoundFontInfo*)load:(NSURL*)url {
    try {
        BOOL secured = [url startAccessingSecurityScopedResource];
        uint64_t fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:url.path error:nil] fileSize];
        int fd = ::open(url.path.UTF8String, O_RDONLY);
        if (secured) [url stopAccessingSecurityScopedResource];
        return fd != -1 ? [SoundFontInfo parse:url fileDescriptor:fd fileSize:fileSize] : nil;
    }
    catch (enum SF2::Format value) {
        return nil;
    }
}

+ (SoundFontInfo*)parse:(NSURL*)url fileDescriptor:(int)fd fileSize:(uint64_t)fileSize {
    SoundFontInfo* result = nil;
    try {
        auto info = SF2::Parser::parse(fd, fileSize);
        ::close(fd);
        fd = -1;

        NSString* embeddedName = [NSString stringWithUTF8String:info.embeddedName.c_str()];
        NSMutableArray* presets = [NSMutableArray arrayWithCapacity:info.presets.size()];
        for (auto it = info.presets.begin(); it != info.presets.end(); ++it) {
            [presets addObject:[[SoundFontInfoPreset alloc] init:*it]];
        }

        [presets sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            SoundFontInfoPreset* patch1 = obj1;
            SoundFontInfoPreset* patch2 = obj2;
            if (patch1.bank < patch2.bank) return NSOrderedAscending;
            if (patch1.bank > patch2.bank) return NSOrderedDescending;
            if (patch1.preset < patch2.preset) return NSOrderedAscending;
            if (patch1.preset == patch2.preset) return NSOrderedSame;
            return NSOrderedDescending;
        }];

        result = [[SoundFontInfo alloc] init:embeddedName url:url presets:presets];
    }
    catch (enum SF2::Format value) {
        if (fd != -1) ::close(fd);
    }

    return result;
}

struct Redirector {
    std::ofstream* file = nullptr;
    std::streambuf* original = nullptr;

    explicit Redirector(char const* fileName)
    {
        if (fileName != nullptr) {
            file = new std::ofstream(fileName);
            original = std::cout.rdbuf(file->rdbuf());
        }
    }

    ~Redirector() {
        if (original != nullptr) std::cout.rdbuf(original);
        if (file != nullptr) file->close();
    }
};

- (void) dump:(NSString*)fileName {
//    if (self.contents == nil) return;
//    Redirector redirector(fileName.UTF8String);
//    auto top = SF2::Parser::parse(self.contents.bytes, self.contents.length);
//    top.dump("");
}

@end
