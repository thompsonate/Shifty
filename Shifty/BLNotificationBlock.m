//
//  BLNotificationBlock.m
//  Shifty
//
//  Created by Nate Thompson on 8/10/17.
//
//

#import <Foundation/Foundation.h>

void (^BLNotificationBlock)() = ^() {
    [NSNotificationCenter.defaultCenter postNotificationName:(NSString *)@"nightShiftToggled"
                                                      object:(id)nil
                                                    userInfo:(NSDictionary *)nil];
};
