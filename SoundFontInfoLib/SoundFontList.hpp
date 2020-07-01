// Copyright © 2019 Brad Howes. All rights reserved.

#ifndef SoundFontList_hpp
#define SoundFontList_hpp

#include <stdbool.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

/// Opaque wrapper around C++ data structure for use in C realm
typedef void const* SoundFontInfo;

/**
 Parse a sound font resource to obtain info on the patches found in the file. The parsing should be robust enough to
 never fail, and so it will always return a non-null value.

 @param data pointer to the raw data of the sound font resource
 @param size the number of bytes in the resource
 */
SoundFontInfo SoundFontParse(void const* data, size_t size);

char const* SoundFontName(SoundFontInfo object);

/**
 Obtain the number of patches found in a previously-parsed sound font.

 @param object the result of a prior SoundFontListWrapper call.
 @returns number of patches in the sound font
 */
size_t SoundFontPatchCount(SoundFontInfo object);

/**
 Obtain the name of the indicated patch.

 @param object the result of a prior SoundFontListWrapper call.
 @param index the index of the patch to query (undefined if index >= PatchInfoListSize())
 @returns name of the patch
*/
char const* SoundFontPatchName(SoundFontInfo object, size_t index);

/**
 Obtain the bank number of the indicated patch.

 @param object the result of a prior SoundFontListWrapper call.
 @param index the index of the patch to query (undefined if index >= PatchInfoListSize())
 @returns bank number where the patch resides
*/
int SoundFontPatchBank(SoundFontInfo object, size_t index);

/**
 Obtain the bank patch number of the indicated patch.

 @param object the result of a prior SoundFontListWrapper call.
 @param index the index of the patch to query (undefined if index >= PatchInfoListSize())
 @returns the patch number of the bank where the patch resides
*/
int SoundFontPatchPatch(SoundFontInfo object, size_t index);

void SoundFontDump(SoundFontInfo object, char const* fileName);

#ifdef __cplusplus
}
#endif
#endif
