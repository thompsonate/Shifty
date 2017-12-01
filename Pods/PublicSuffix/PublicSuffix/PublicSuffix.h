//
//  PublicSuffix.h
//  PublicSuffix
//
//  Created by Enrico Ghirardi on 28/11/2017.
//  Copyright © 2017 Enrico Ghirardi. All rights reserved.
//

#import <Cocoa/Cocoa.h>

//! Project version number for PublicSuffix.
FOUNDATION_EXPORT double PublicSuffixVersionNumber;

//! Project version string for PublicSuffix.
FOUNDATION_EXPORT const unsigned char PublicSuffixVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <PublicSuffix/PublicHeader.h>

@interface NSURL (WebNSURLExtras)
- (NSString *)_web_hostString;
@end

@interface NSString (WebNSURLExtras)
- (NSString *)_webkit_decodeHostName;
- (NSString *)_webkit_encodeHostName;
@end
