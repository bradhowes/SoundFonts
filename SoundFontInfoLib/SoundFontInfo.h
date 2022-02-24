// Copyright © 2019 Brad Howes. All rights reserved.

#pragma once

#import <Foundation/Foundation.h>

/**
 A preset found in an SF2 file.
 */
@interface SoundFontInfoPreset : NSObject

/// The name of the preset
@property (nonatomic, retain) NSString* name;
/// The MIDI bank number where the preset resides
@property (nonatomic, assign) int bank;
/// The MIDI patch number in the bank where the preset resides
@property (nonatomic, assign) int program;

/**
 Create a new preset entry
 
 @param name the name of the preset
 @param bank the MIDI bank to use to select the preset
 @param program the MIDI patch/preset to use to select the preset
 */
- (id) init:(NSString*)name bank:(int)bank program:(int)program;

@end

/**
 Collection of presets and metadata for a specific SF2 soundfont file.
 */
@interface SoundFontInfo : NSObject

/// The location of the file that was processed
@property (nonatomic, retain) NSURL* url;
/// The embedded name found in the file
@property (nonatomic, retain) NSString* embeddedName;
/// The author name found in the file
@property (nonatomic, retain) NSString* embeddedAuthor;
/// The comment found in the file
@property (nonatomic, retain) NSString* embeddedComment;
/// The copyright notice found in the file
@property (nonatomic, retain) NSString* embeddedCopyright;
/// Collection of presets found in the file
@property (nonatomic, retain) NSArray<SoundFontInfoPreset*>* presets;

/**
 Class method that creates a new SoundFontInfo instance by using the efficient Parser class
 
 @param url the location of the SF2 file to process
 
 @returns new SoundFontInfo instance
 */
+ (SoundFontInfo*)loadViaParser:(NSURL*)url;

/**
 Class method that creates a new SoundFontInfo instance by using the robust File class. This should result in the same
 results as the above method.
 
 @param url the location of the SF2 file to process
 
 @returns new SoundFontInfo instance
 */
+ (SoundFontInfo*)loadViaFile:(NSURL*)url;

/**
 Class method that creates a new SoundFontInfo instance by using the efficient Parser class on an open file descriptor.
 
 @param url the location of the SF2 file to process (only used for book-keeping)

 @returns new SoundFontInfo instance
 */
+ (SoundFontInfo*)parseViaParser:(NSURL*)url;

/**
 Class method that creates a new SoundFontInfo instance by using the robust File class on an open file descriptor.
 
 @param url the location of the SF2 file to process (only used for book-keeping)

 @returns new SoundFontInfo instance
 */
+ (SoundFontInfo*)parseViaFile:(NSURL*)url;

/**
 Constructor for SoundFontInfo instance.
 
 @param name the name that was embedded in the SF2 file
 @param url the URL that was used for processing
 @param embeddedAuthor the name of the author found in the SF2 file
 @param embeddedComment the comment found in the SF2 file
 @param embeddedCopyright the copyright notice found in the SF2 file
 @param presets the collection of SoundFontInfoPreset instances found in the SF2 file
 */
- (id) init:(NSString*)name
        url:(NSURL*)url
     author:(NSString*)embeddedAuthor
    comment:(NSString*)embeddedComment
  copyright:(NSString*)embeddedCopyright
    presets:(NSArray<SoundFontInfoPreset*>*)presets;

@end
