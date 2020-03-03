// Copyright © 2020 Brad Howes. All rights reserved.

#import <objc/runtime.h>
#import <AVFoundation/AVFoundation.h>

@implementation AUAudioUnit(SoundFontsAU)


/// Perform customization on AUAudioUnit class to install a custom allocateRenderResourcesAndReturnError method
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];

        SEL originalSelector = @selector(allocateRenderResourcesAndReturnError:);
        SEL swizzledSelector = @selector(swizzled_allocateRenderResourcesAndReturnError:);

        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);

        BOOL didAddMethod = class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod),
                                            method_getTypeEncoding(swizzledMethod));
        if (didAddMethod) {
            class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod),
                                method_getTypeEncoding(originalMethod));
        }
        else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}

/**
 Customized method that forces all output AUAudioUnitBus instances to allocate their own buffers. If this is not done
 then the audio unit will not work in AUM and it will emit constant errors.s
 */
- (BOOL)swizzled_allocateRenderResourcesAndReturnError:(NSError **)outError {

    for (int index = 0; index < self.outputBusses.count; ++index) {
        self.outputBusses[index].shouldAllocateBuffer = YES;
    }

    // Call original method now that we are done.
    return [self swizzled_allocateRenderResourcesAndReturnError: outError];
}

@end
