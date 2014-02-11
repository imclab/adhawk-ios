//
//  AppDelegate.m
//  adhawk
//
//  Created by James Snavely on 3/3/12.
//  Copyright (c) 2012 Sunlight Foundation. All rights reserved.
//

#import "AppDelegate.h"
#import "Settings.h"
#import "AdHawkPreferencesManager.h"
#import "AFNetworkActivityIndicatorManager.h"

@implementation AppDelegate

@synthesize window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[AdHawkPreferencesManager sharedInstance] setupPreferences];
    
    // Audio Session setup
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryRecord error:nil];
    [audioSession setPreferredSampleRate:44100.0 error:nil];
    [audioSession setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];

    application.statusBarStyle = UIStatusBarStyleBlackOpaque;
    // Override point for customization after application launch.
    if (TESTING == YES) {
        [TestFlight takeOff:TESTFLIGHT_APP_TOKEN];
        NSLog(@"TestFlight run");
    } else {
        NSLog(@"No testing");
    }

    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];

//    Set up views
    self.window.rootViewController = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil]
                                      instantiateViewControllerWithIdentifier:@"AppNavigationController"];


    [self.window makeKeyAndVisible];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
    [[AVAudioSession sharedInstance] setActive:NO error:nil];
    [[AdHawkPreferencesManager sharedInstance] updateStoredPreferences];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
    [[AVAudioSession sharedInstance] setActive:NO error:nil];
    [[AdHawkPreferencesManager sharedInstance] updateStoredPreferences];
}

@end
