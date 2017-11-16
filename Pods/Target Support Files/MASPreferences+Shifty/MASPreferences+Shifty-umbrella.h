#ifdef __OBJC__
#import <Cocoa/Cocoa.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "MASPreferences.h"
#import "MASPreferencesViewController.h"
#import "MASPreferencesWindowController.h"

FOUNDATION_EXPORT double MASPreferences_ShiftyVersionNumber;
FOUNDATION_EXPORT const unsigned char MASPreferences_ShiftyVersionString[];

