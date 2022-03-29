//
//  ChorusAudioUnit.h
//  Chorus
//
//  Created by Brad Howes on 27/03/2022.
//  Copyright © 2022 Brad Howes. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
#import "ChorusDSPKernelAdapter.h"

// Define parameter addresses.
extern const AudioUnitParameterID myParam1;

@interface ChorusAudioUnit : AUAudioUnit

@property (nonatomic, readonly) ChorusDSPKernelAdapter *kernelAdapter;
- (void)setupAudioBuses;
- (void)setupParameterTree;
- (void)setupParameterCallbacks;
@end
