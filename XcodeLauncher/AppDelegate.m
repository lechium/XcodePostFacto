//
//  AppDelegate.m
//  XcodeLauncher
//
//  Created by Kevin Bradley on 5/5/15.
//  Copyright (c) 2015 Landon Fuller. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@property (strong) NSString *frameworkLocation;
@property (strong) NSString *xcodeLocation;
@property (strong) NSMetadataQuery *q;
@end

@implementation AppDelegate

@synthesize q;


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    [self searchForAppWithID:@"com.apple.dt.Xcode"];
    
   // [self performXcodeLaunch];
    
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (void)performXcodeLaunch
{
    //Find XPF Framework
    self.frameworkLocation = [self findXPFFramework];
    
    if (self.frameworkLocation == nil)
    {
        NSLog(@"couldnt find XPF framework or user cancelled");
        return;
    }
    
    NSString *launchString = [NSString stringWithFormat:@"/usr/bin/env DYLD_INSERT_LIBRARIES=%@ %@ &", self.frameworkLocation, self.xcodeLocation];
    system([launchString UTF8String]);
    
    //dont wanna keep the app launched in the BG, but not sure how long itll take xcode to get up and running...
    //hopefully not more than 20 seconds.
    
    [NSTimer scheduledTimerWithTimeInterval:20 target:self selector:@selector(quitAppTimed) userInfo:nil repeats:false];
}

- (void)quitAppTimed
{
    [[NSApplication sharedApplication] terminate:nil];
    
}


- (void)searchForAppWithID:(NSString *)appName
{
    q = [[NSMetadataQuery alloc] init];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishedFindingApps:) name:NSMetadataQueryDidFinishGatheringNotification object:q];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"kMDItemCFBundleIdentifier == %@", appName];
    [q setPredicate:predicate];
    [q startQuery];
}


- (void)searchForAppWithName:(NSString *)appName
{
    q = [[NSMetadataQuery alloc] init];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(foundApp:) name:NSMetadataQueryDidUpdateNotification object:q];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(foundApp:) name:NSMetadataQueryGatheringProgressNotification object:q];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishedFindingApps:) name:NSMetadataQueryDidFinishGatheringNotification object:q];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"kMDItemFSName == %@", appName];
    [q setPredicate:predicate];
    [q startQuery];
}

- (void)foundApp:(NSNotification *)n
{
   
}

- (void)finishedFindingApps:(NSNotification *)n
{
   // LOG_SELF_INFO;
    
  
    
    NSMetadataQuery *query = [n object];
    NSMutableArray *newFileListArray = [[NSMutableArray alloc] init];
    //  NSLog(@"finished finding apps: %@", [query results]);
    for (NSMetadataItem *file in [query results])
    {
        NSString *filePath = [file valueForKey:NSMetadataItemPathKey];
      //  NSLog(@"filePath: %@", filePath);
        NSString *filePathSearch = [filePath stringByAppendingPathComponent:@"Contents"]; //crude check to make sure its not an iOS app
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePathSearch])
        {
            NSString *creationDate = [file valueForKey:NSMetadataItemFSCreationDateKey];
            //    NSDictionary  *fileAttrs = [[NSBundle bundleWithPath:filePath] infoDictionary];
            NSDictionary *fileInfo = @{@"filePath": filePath, @"creationDate": creationDate};
            [newFileListArray addObject:fileInfo];
        }
    }
    
    [query stopQuery];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSMetadataQueryDidFinishGatheringNotification object:query];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSMetadataQueryDidUpdateNotification object:query];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSMetadataQueryGatheringProgressNotification object:query];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:YES];
    NSArray *sortedArray = [newFileListArray sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    NSString *mostRecentApp = [[sortedArray lastObject] valueForKey:@"filePath"];

    //NSLog(@"mostRecentXcode: %@", mostRecentApp);
    self.xcodeLocation = [mostRecentApp stringByAppendingPathComponent:@"Contents/MacOS/Xcode"];
    
    NSLog(@"xcode location: %@", self.xcodeLocation);
    [self performXcodeLaunch];
    
}

- (NSString *)findXPFFramework
{
    NSFileManager *man = [NSFileManager defaultManager];
    NSString *binaryName = @"xpf-bootstrap.framework/xpf-bootstrap";
    NSString *path = [[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Frameworks/"] stringByAppendingPathComponent:binaryName];
    
    if ([man fileExistsAtPath:path]) return path;
    
    path = [@"/Library/Frameworks" stringByAppendingPathComponent:binaryName];
    
    
    if ([man fileExistsAtPath:path]) return path;
    
    path = [@"/System/Library/Frameworks" stringByAppendingPathComponent:binaryName];
    
    
    if ([man fileExistsAtPath:path]) return path;
    
    return [self userSelectFPX];
    
}

- (NSString *)userSelectFPX
{
    NSOpenPanel *op = [[NSOpenPanel alloc] init];
    op.canChooseDirectories = TRUE;
    op.canChooseFiles = FALSE;
    op.allowsMultipleSelection = FALSE;
    op.allowedFileTypes = @[@"framework"];
    
    
    op.title = @"Select xpf-bootstrap framework";
    op.message = @"The xpf-bootstrap framework is required to launch Xcode 6.3.x, please select its location";
    
    if ([op runModal] == NSFileHandlingPanelOKButton)
    {
        return [[[op URL] path] stringByAppendingPathComponent:@"xpf-bootstrap"];
    }
    
    return nil;
    
    
}


@end
