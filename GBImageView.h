// Archy - Copyright (c) 2011-2013
// Author: Giuseppe Basile
// Sharit Application SL. All rights reserved

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>

@interface GBImageView : NSView

@property (strong, nonatomic) NSImage *image;

#pragma mark - Animate Image switching
@property (strong, nonatomic) CATransition *transition;

#pragma mark - Asynchronous Image Request
- (void)setImageWithURL:(NSURL *)url;

- (void)setImageWithURL:(NSURL *)url
       placeholderImage:(NSImage *)placeholderImage;

#pragma mark - Cache System
+ (NSTimeInterval)timeoutInterval; // Default 1 day
+ (void)setTimeoutInterval:(NSTimeInterval)timeoutInterval;

+ (void)resetCacheForURL:(NSURL *)url;
+ (void)clearImageCache;

@end
