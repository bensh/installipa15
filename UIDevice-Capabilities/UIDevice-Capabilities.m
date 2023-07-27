#import <GraphicsServices/GraphicsServices.h>
#import <dlfcn.h>
#import <UIKit/UIKit.h>


@implementation UIDevice (Capabilities)

static BOOL (*MGGetBoolAnswer)(NSString *capability);

- (BOOL) supportsCapability: (NSString *) capability
{

    if (!MGGetBoolAnswer) {
        void *libMobileGestalt = dlopen("/usr/lib/libMobileGestalt.dylib", RTLD_LAZY);
        if (libMobileGestalt)
            MGGetBoolAnswer = dlsym(libMobileGestalt, "MGGetBoolAnswer");
    }
    if (MGGetBoolAnswer != NULL)
        return MGGetBoolAnswer(capability);
    return NO;
}

@end
