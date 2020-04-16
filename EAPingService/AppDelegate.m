//
//  AppDelegate.m
//  EAPingService
//
//  Created by eAssh on 2020/4/16.
//  Copyright © 2020 eAssh. All rights reserved.
//

#import "AppDelegate.h"
#import "PingViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    self.window.rootViewController = [[PingViewController alloc] init];
    [self.window makeKeyAndVisible];
    return YES;
}


@end
