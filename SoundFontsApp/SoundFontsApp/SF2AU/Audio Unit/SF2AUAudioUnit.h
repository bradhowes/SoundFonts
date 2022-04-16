//
//  SF2SAUAudioUnit.h
//  SF2SAU
//
//  Created by Brad Howes on 16/04/2022.
//  Copyright © 2022 Brad Howes. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
#import "SF2AUDSPKernelAdapter.h"

// Define parameter addresses.
extern const AudioUnitParameterID myParam1;

@interface SF2AUAudioUnit : AUAudioUnit

@property (nonatomic, readonly) SF2AUDSPKernelAdapter *kernelAdapter;
- (void)setupAudioBuses;
- (void)setupParameterTree;
- (void)setupParameterCallbacks;
@end
