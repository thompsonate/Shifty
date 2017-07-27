//
//  CBBlueLightClient.h
//  Shifty
//
//  Created by Nate Thompson and Cal Stephens on 5/5/17.
//
//

#import <Foundation/Foundation.h>

// Partial header for CBBlueLightClient in private CoreBrightness API
@interface CBBlueLightClient : NSObject
- (BOOL)setStrength:(float)strength commit:(BOOL)commit;
- (BOOL)setEnabled:(BOOL)enabled;
- (BOOL)getStrength:(float*)strength;
- (BOOL)getCCT:(float*)arg1;
- (BOOL)getBlueLightStatus:(struct { BOOL x1; BOOL x2; BOOL x3; int x4; struct { struct { int x_1_2_1; int x_1_2_2; } x_5_1_1; struct { int x_2_2_1; int x_2_2_2; } x_5_1_2; } x5; unsigned long x6; }*)arg1;
@end
