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

typedef struct {
    int hour;
    int minute;
} Time;

typedef struct {
    Time fromTime;
    Time toTime;
} Schedule;

typedef struct {
    BOOL active;
    BOOL enabled;
    BOOL sunSchedulePermitted;
    int mode;
    Schedule schedule;
    unsigned long long disableFlags;
} StatusData;

- (BOOL)setStrength:(float)strength commit:(BOOL)commit;
- (BOOL)setEnabled:(BOOL)enabled;
- (BOOL)setMode:(int)mode;
- (BOOL)setSchedule:(Schedule *)arg1;
- (BOOL)getStrength:(float*)strength;
- (BOOL)getCCT:(float*)arg1;
- (BOOL)getBlueLightStatus:(StatusData *)arg1;
- (void)setStatusNotificationBlock:(id /* block */)arg1;
+ (BOOL)supportsBlueLightReduction;
@end
