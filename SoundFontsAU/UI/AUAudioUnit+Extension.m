// Copyright © 2020 Brad Howes. All rights reserved.

#import <objc/runtime.h>
#import <AVFoundation/AVFoundation.h>

@implementation AUAudioUnit(SoundFontsAU)


/// Perform customization on AUAudioUnit class to install a custom allocateRenderResourcesAndReturnError method
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self swizzleFrom: @selector(allocateRenderResourcesAndReturnError:)
                       to: @selector(swizzled_allocateRenderResourcesAndReturnError:)];
    });
}

+ (void)swizzleFrom:(SEL)original to:(SEL)swizzled {
    Class class = [self class];

    Method originalMethod = class_getInstanceMethod(class, original);
    Method swizzledMethod = class_getInstanceMethod(class, swizzled);

    BOOL didAddMethod = class_addMethod(class, original, method_getImplementation(swizzledMethod),
                                        method_getTypeEncoding(swizzledMethod));
    if (didAddMethod) {
        class_replaceMethod(class, swizzled, method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    }
    else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

+ (SEL)getterForPropertyWithName:(NSString*)name {
    const char* propertyName = [name cStringUsingEncoding: NSASCIIStringEncoding];
    objc_property_t prop = class_getProperty(self, propertyName);

    const char* selectorName = property_copyAttributeValue(prop, "G");
    if (selectorName == NULL) {
        selectorName = [name cStringUsingEncoding: NSASCIIStringEncoding];
    }

    NSString* selectorString = [NSString stringWithCString:selectorName encoding: NSASCIIStringEncoding];
    return NSSelectorFromString(selectorString);
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
