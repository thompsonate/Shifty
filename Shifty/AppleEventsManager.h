//
//  AppleEventsManager.h
//  Shifty
//
//  Created by Nate Thompson on 2/13/19.
//


@interface AppleEventsManager : NSObject

typedef NS_ENUM(NSInteger, PrivacyConsentState) {
    PrivacyConsentStateUndetermined NS_SWIFT_NAME(undetermined),
    PrivacyConsentStateGranted NS_SWIFT_NAME(granted),
    PrivacyConsentStateDenied NS_SWIFT_NAME(denied)
};

+ (PrivacyConsentState)automationConsentForBundleIdentifier:(NSString *)bundleIdentifier;

@end
