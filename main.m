#include <dlfcn.h>
#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#import "UIDevice-Capabilities/UIDevice-Capabilities.h"

#define EXECUTABLE_VERSION @"0.1"

#define KEY_INSTALL_TYPE @"User"
#define KEY_SDKPATH "/System/Library/PrivateFrameworks/MobileInstallation.framework/MobileInstallation"

#define IPA_FAILED -1

typedef int (*MobileInstallationInstall)(NSString *path, NSDictionary *dict, void *na, NSString *backpath);
typedef int (*MobileInstallationUninstall)(NSString *bundleID, NSDictionary *dict, void *na);

@interface LSApplicationWorkspace : NSObject
+ (LSApplicationWorkspace *)defaultWorkspace;
- (BOOL)installApplication:(NSURL *)path withOptions:(NSDictionary *)options;
- (BOOL)uninstallApplication:(NSString *)identifier withOptions:(NSDictionary *)options;
- (BOOL)applicationIsInstalled:(NSString *)appIdentifier;
- (NSArray *)allInstalledApplications;
- (NSArray *)allApplications;
- (NSArray *)applicationsOfType:(unsigned int)appType; // 0 for user, 1 for system
@end

@interface LSApplicationProxy : NSObject
+ (LSApplicationProxy *)applicationProxyForIdentifier:(id)appIdentifier;
@property(readonly) NSString * applicationIdentifier;
@property(readonly) NSString * bundleVersion;
@property(readonly) NSString * bundleExecutable;
@property(readonly) NSArray * deviceFamily;
@property(readonly) NSURL * bundleContainerURL;
@property(readonly) NSString * bundleIdentifier;
@property(readonly) NSURL * bundleURL;
@property(readonly) NSURL * containerURL;
@property(readonly) NSURL * dataContainerURL;
@property(readonly) NSString * localizedShortName;
@property(readonly) NSString * localizedName;
@property(readonly) NSString * shortVersionString;
@end

static NSString *SystemVersion = nil;
static int DeviceModel = 0;

//static BOOL isUninstall = NO;
static BOOL isGetInfo = NO;
static BOOL isListing = NO;
//static BOOL isBackup = NO;
//static BOOL isBackupFull = NO;

//static BOOL cleanInstall = NO;
static int quietInstall = 0; //0 is show all outputs, 1 is to show only errors, 2 is to show nothing
//static BOOL forceInstall = NO;
//static BOOL removeMetadata = NO;
//static BOOL deleteFile = NO;
//static BOOL notRestore = NO;

static NSArray *getInstalledApplications() {
    if (kCFCoreFoundationVersionNumber < 1140.10) {
        NSDictionary *mobileInstallationPlist = [NSDictionary dictionaryWithContentsOfFile:@"/private/var/mobile/Library/Caches/com.apple.mobile.installation.plist"];
        NSDictionary *installedAppDict = (NSDictionary*)[mobileInstallationPlist objectForKey:@"User"];

        NSArray * identifiers = [[installedAppDict allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];

        return identifiers;
    } else {
        Class LSApplicationWorkspace_class = objc_getClass("LSApplicationWorkspace");
        if (LSApplicationWorkspace_class) {
            LSApplicationWorkspace *workspace = [LSApplicationWorkspace_class performSelector:@selector(defaultWorkspace)];
            if (workspace) {
                NSArray *allApps = [workspace applicationsOfType:0];
                NSMutableArray *identifiers = [NSMutableArray arrayWithCapacity:[allApps count]];
                for (LSApplicationProxy *appBundle in allApps)
                    [identifiers addObject:appBundle.bundleIdentifier];
                return [identifiers sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
            }
        }
    }
    return nil;
}

static NSString *formatDictValue(NSObject *object) {
    return object ? (NSString *)object : @"";
}

//static NSString *getBestString(NSString *main, NSString *minor) {
//    return (minor && [minor length] > 0) ? minor : (main ? main : @"");
//}

static NSDictionary *getInstalledAppInfo(NSString *appIdentifier) {
    if (kCFCoreFoundationVersionNumber < 1140.10) {
        NSDictionary *mobileInstallationPlist = [NSDictionary dictionaryWithContentsOfFile:@"/private/var/mobile/Library/Caches/com.apple.mobile.installation.plist"];
        NSDictionary *installedAppDict = (NSDictionary*)[mobileInstallationPlist objectForKey:@"User"];

        NSDictionary *appInfo = [installedAppDict objectForKey:appIdentifier];
        if (appInfo) {
            NSMutableDictionary *info = [NSMutableDictionary dictionaryWithCapacity:8];
            [info setObject:formatDictValue([appInfo objectForKey:@"CFBundleIdentifier"]) forKey:@"APP_ID"];
            [info setObject:formatDictValue([appInfo objectForKey:@"Container"]) forKey:@"BUNDLE_PATH"];
            [info setObject:formatDictValue([appInfo objectForKey:@"Path"]) forKey:@"APP_PATH"];
            [info setObject:formatDictValue([appInfo objectForKey:@"Container"]) forKey:@"DATA_PATH"];
            [info setObject:formatDictValue([appInfo objectForKey:@"CFBundleVersion"]) forKey:@"VERSION"];
            [info setObject:formatDictValue([appInfo objectForKey:@"CFBundleShortVersionString"]) forKey:@"SHORT_VERSION"];
            [info setObject:formatDictValue([appInfo objectForKey:@"CFBundleName"]) forKey:@"NAME"];
            [info setObject:formatDictValue([appInfo objectForKey:@"CFBundleDisplayName"]) forKey:@"DISPLAY_NAME"];
            return info;
        }
    } else {
        Class LSApplicationWorkspace_class = objc_getClass("LSApplicationWorkspace");
        if (LSApplicationWorkspace_class) {
            LSApplicationWorkspace *workspace = [LSApplicationWorkspace_class performSelector:@selector(defaultWorkspace)];
            if (workspace && [workspace applicationIsInstalled:appIdentifier]) {
                Class LSApplicationProxy_class = objc_getClass("LSApplicationProxy");
                if (LSApplicationProxy_class) {
                    LSApplicationProxy *app = [LSApplicationProxy_class applicationProxyForIdentifier:appIdentifier];
                    if (app) {
                        NSMutableDictionary *info = [NSMutableDictionary dictionaryWithCapacity:9];
                        [info setObject:formatDictValue(app.bundleIdentifier) forKey:@"APP_ID"];
                        [info setObject:formatDictValue([app.bundleContainerURL path]) forKey:@"BUNDLE_PATH"];
                        [info setObject:formatDictValue([app.bundleURL path]) forKey:@"APP_PATH"];
                        [info setObject:formatDictValue([app.dataContainerURL path]) forKey:@"DATA_PATH"];
                        [info setObject:formatDictValue(app.bundleVersion) forKey:@"VERSION"];
                        [info setObject:formatDictValue(app.shortVersionString) forKey:@"SHORT_VERSION"];
                        [info setObject:formatDictValue(app.localizedName) forKey:@"NAME"];
                        [info setObject:formatDictValue(app.localizedShortName) forKey:@"DISPLAY_NAME"];
                        return info;
                    }
                }
            }
        }
    }
    return nil;
}

int main (int argc, char **argv, char **envp) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    freopen("/dev/null", "w", stderr); //Suppress output from NSLog
    
    //Get system info
    SystemVersion = [UIDevice currentDevice].systemVersion;
    NSString *deviceString = [UIDevice currentDevice].model;
    if ([deviceString isEqualToString:@"iPhone"] || [deviceString isEqualToString:@"iPod touch"])
        DeviceModel = 1;
    else if ([deviceString isEqualToString:@"iPad"])
        DeviceModel = 2;
    else
        DeviceModel = 3; //Apple TV maybe?
    
    //Process parameters
    NSArray *arguments = [[NSProcessInfo processInfo] arguments];
    
    if ([arguments count] < 1) {
        [pool release];
        return IPA_FAILED;
    }

    
    NSString *executableName = [[arguments objectAtIndex:0] lastPathComponent];
    
    NSString *helpString = [NSString stringWithFormat:@"Usage: %@ [OPTION]... [FILE]...\n       %@ -i [APP_ID]...\n       %@ -l\n       \nOptions:\n    -a  Show tool about information.\n    -h  Display this usage information.\n    -i  Display information of installed application(s).\n    -l  List identifiers of all installed App Store applications.", executableName, executableName, executableName];
    
    NSDate *today = [NSDate date];
    
    NSDateFormatter *currentFormatter = [[NSDateFormatter alloc] init];
    
    [currentFormatter setDateFormat:@"yyyy"];
    
    NSString *aboutString = [NSString stringWithFormat:@"About %@\nBrowse installed IPAs via command line.\nVersion: %@\nAuthor: Merlin Mao.\nUpdates: bensh\n\nCopyright \u00A9 2012%@. All rights reserved.", executableName, EXECUTABLE_VERSION, [[currentFormatter stringFromDate:today] isEqualToString:@"2012"] ? @"" : [@"-" stringByAppendingString:[currentFormatter stringFromDate:today]]];
    
    [currentFormatter release];
    
    if ([arguments count] == 1) {
        printf("%s\n", [helpString cStringUsingEncoding:NSUTF8StringEncoding]);
        [pool release];
        return 0;
    }
    
    
    if ([arguments count] >= 3) {
        NSMutableArray *identifiers = [NSMutableArray array];
        
        NSString *op1 = [arguments objectAtIndex:1];
        if ([op1 isEqualToString:@"-i"]) {
            isGetInfo = YES;
            for (unsigned int i=2; i<[arguments count]; i++)
                [identifiers addObject:[arguments objectAtIndex:i]];
        }
        
        if (isGetInfo) {
            if ([identifiers count] < 1) {
                printf("You must specify at least one application identifier.\n");
                [pool release];
                return IPA_FAILED;
            }
            
            NSArray *installedApps = getInstalledApplications();
            
            for (unsigned int i=0; i<[identifiers count]; i++) {
                NSString *identifier = [identifiers objectAtIndex:i];
                if ([installedApps containsObject:identifier]) {
                    NSDictionary *installedAppInfo = getInstalledAppInfo(identifier);
                    
                    NSString *appDirPath = [installedAppInfo objectForKey:@"BUNDLE_PATH"];
                    NSString *appPath = [installedAppInfo objectForKey:@"APP_PATH"];
                    NSString *dataPath = [installedAppInfo objectForKey:@"DATA_PATH"];
                    NSString *appName = [installedAppInfo objectForKey:@"NAME"];
                    NSString *appDisplayName = [installedAppInfo objectForKey:@"DISPLAY_NAME"];
                    NSString *appVersion = [installedAppInfo objectForKey:@"VERSION"];
                    NSString *appShortVersion = [installedAppInfo objectForKey:@"SHORT_VERSION"];
                    
                    printf("Identifier: %s\n", [identifier cStringUsingEncoding:NSUTF8StringEncoding]);
                    if ([appVersion length] > 0)
                        printf("Version: %s\n", [appVersion cStringUsingEncoding:NSUTF8StringEncoding]);
                    if ([appShortVersion length] > 0)
                        printf("Short Version: %s\n", [appShortVersion cStringUsingEncoding:NSUTF8StringEncoding]);
                    if ([appName length] > 0)
                        printf("Name: %s\n", [appName cStringUsingEncoding:NSUTF8StringEncoding]);
                    if ([appDisplayName length] > 0)
                        printf("Display Name: %s\n", [appDisplayName cStringUsingEncoding:NSUTF8StringEncoding]);
                    if ([appDirPath length] > 0)
                        printf("Bundle: %s\n", [appDirPath cStringUsingEncoding:NSUTF8StringEncoding]);
                    if ([appPath length] > 0)
                        printf("Application: %s\n", [appPath cStringUsingEncoding:NSUTF8StringEncoding]);
                    if ([dataPath length] > 0)
                        printf("Data: %s\n", [dataPath cStringUsingEncoding:NSUTF8StringEncoding]);
                } else {
                    if (quietInstall < 2)
                        printf("Application \"%s\" is not installed.\n", [identifier cStringUsingEncoding:NSUTF8StringEncoding]);
                }
                if (i < [identifiers count] - 1)
                    printf("\n");
            }
            return 0;
        }
        
        
    }

    BOOL noParameters = NO;
    BOOL showHelp = NO;
    BOOL showAbout = NO;
    
    for (unsigned int i=1; i<[arguments count]; i++) {
        NSString *arg = [arguments objectAtIndex:i];
        if ([arg hasPrefix:@"-" ]) {
            if ([arg length] < 2 || noParameters) {
                printf("Invalid parameters.\n");
                [pool release];
                return IPA_FAILED;
            }
            
            for (unsigned int j=1; j<[arg length]; j++) {
                NSString *p = [arg substringWithRange:NSMakeRange(j, 1)];
                if ([p isEqualToString:@"l"])
                    isListing = YES;
                else if ([p isEqualToString:@"a"])
                    showAbout = YES;
                else if ([p isEqualToString:@"h"])
                    showHelp = YES;
                else if ([p isEqualToString:@"i"] || [p isEqualToString:@"I"])
                    isGetInfo = YES;
                else {
                    printf("Invalid parameter '%s'.\n", [p cStringUsingEncoding:NSUTF8StringEncoding]);
                    [pool release];
                    return IPA_FAILED;
                }
            }
        }
    }

    if (showAbout) {
        printf("%s\n", [aboutString cStringUsingEncoding:NSUTF8StringEncoding]);
        [pool release];
        return 0;
    }

    if (isListing) {
        getInstalledApplications();
        if ([arguments count] != 2) {
            printf("Invalid parameters.\n");
            [pool release];
            return IPA_FAILED;
        } else {
            NSArray * identifiers = getInstalledApplications();

            for (unsigned int i=0; i<[identifiers count]; i++)
                printf("%s\n", [(NSString *)[identifiers objectAtIndex:i] cStringUsingEncoding:NSUTF8StringEncoding]);
            [pool release];
            return 0;
        }
    }

    if (showHelp) {
        printf("%s\n", [helpString cStringUsingEncoding:NSUTF8StringEncoding]);
        [pool release];
        return 0;
    }
}
