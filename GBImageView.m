// Archy - Copyright (c) 2011-2013
// Author: Giuseppe Basile
// Sharit Application SL. All rights reserved

#import "GBImageView.h"
#import <EGOCache/EGOCache.h>
#import <CommonCrypto/CommonDigest.h>

static const int kGBTimeInterval1Day = 1 * 24 * 60 * 60;
static EGOCache *sharedInstance = nil;

@interface GBImageView ()
@property (nonatomic, strong) NSImageView *currentImageView;
@property (nonatomic, strong) NSURLConnection *currentConnection;
@property (nonatomic, strong) NSURL *currentRequestURL;
@property (nonatomic, strong) NSMutableData *imageData;
@property (nonatomic, readonly) EGOCache *imageCache;
@end

@implementation GBImageView

- (void)awakeFromNib
{
    self.wantsLayer = YES;
    [super awakeFromNib];
}

#pragma mark - Animate Image switching
- (void)setImage:(NSImage *)image
{
    [self setImage:image shouldCancelPreviousRequest:YES];
}

- (void)setImage:(NSImage *)image shouldCancelPreviousRequest:(BOOL)shouldCancelPreviousRequest
{
    if (_image == image) {
        return;
    }
    _image = image;
    
    if (shouldCancelPreviousRequest) {
        [self cancelPreviousRequest];
    }

    NSImageView *newImageView = nil;
    if (image) {
        newImageView = [[NSImageView alloc] initWithFrame:self.bounds];
        newImageView.image = image;
        newImageView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    }
    
    if (_currentImageView && newImageView) {
        [self.animator replaceSubview:_currentImageView with:newImageView];
    } else {
        if (_currentImageView) {
            [_currentImageView.animator removeFromSuperview];
        }
        
        if (newImageView) {
            [self.animator addSubview:newImageView];
        }
    }
    
    _currentImageView = newImageView;
}

- (void)setTransition:(CATransition *)transition
{
    _transition = transition;
    [self setupTransition];
}

- (void)viewWillStartLiveResize
{
    [self resetAnimations];
    [super viewWillStartLiveResize];
}

- (void)resetAnimations
{
    [self cleanTransition];
    [self setupTransition];
}

- (void)cleanTransition
{
    [self.layer removeAllAnimations];
}

- (void)setupTransition
{
    if (self.transition) {
        self.animations = @{@"subviews": self.transition};
    } else {
        NSMutableDictionary *animations = [self.animations mutableCopy];
        [animations removeObjectForKey:@"subviews"];
        self.animations = animations;
    }
}

#pragma mark Asynchronous Image Request
- (void)setImageWithURL:(NSURL *)url
{
    [self setImageWithURL:url placeholderImage:nil];
}

- (void)setImageWithURL:(NSURL *)url
       placeholderImage:(NSImage *)placeholderImage
{
    NSImage *theCachedImage = [self.imageCache imageForKey:[[self class] cacheKeyforURL:url]];
    if (theCachedImage) {
        [self setImage:theCachedImage shouldCancelPreviousRequest:NO];
        return;
    }
    
    if ([self.currentRequestURL isEqual:url]) {
        return;
    }
    [self cancelPreviousRequest];
    
    if (placeholderImage) {
        [self setImage:placeholderImage shouldCancelPreviousRequest:NO];
    }

    self.currentRequestURL = url;
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:self.currentRequestURL];
    self.currentConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
    self.imageData = [NSMutableData data];
}

- (void)cancelPreviousRequest
{
    [self.currentConnection cancel];
    self.currentConnection = nil;
    self.currentRequestURL = nil;
}

#pragma mark - NSURLConnection (delegate)
- (void)connection:(NSURLConnection *)aConnection didReceiveData:(NSData *)data
{
    [self.imageData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)aConnection
{
    if (self.currentConnection) {
        [self setImage:[[NSImage alloc] initWithData:self.imageData] shouldCancelPreviousRequest:NO];
        [self.imageCache setImage:self.image forKey:[[self class] cacheKeyforURL:self.currentRequestURL] withTimeoutInterval:[[self class] timeoutInterval]];
        self.currentConnection = nil;
    }
}

#pragma mark - Cache System
- (EGOCache *)imageCache
{
    return [[self class] imageCache];
}

+ (EGOCache *)imageCache
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[EGOCache alloc] initWithCacheDirectory:[[self class] cacheDirectory]];
    });
    
    return sharedInstance;
}

+ (NSString *)cacheDirectory
{
    NSString *cachesDir = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
    return [[cachesDir stringByAppendingPathComponent:[[NSBundle mainBundle] bundleIdentifier]] stringByAppendingPathComponent:@"GBImageCache"];
}

+ (NSTimeInterval)timeoutInterval
{
    NSTimeInterval timeInterval = [self.imageCache defaultTimeoutInterval];
    if (!timeInterval) {
        timeInterval = kGBTimeInterval1Day;
    }
    
    return timeInterval;
}

+ (void)setTimeoutInterval:(NSTimeInterval)timeoutInterval
{
    [self.imageCache setDefaultTimeoutInterval:timeoutInterval];
}

+ (NSString *)cacheKeyforURL:(NSURL *)url
{
    NSString *stringURL = [url absoluteString];
    const char *UTF8URL = [stringURL UTF8String];
    unsigned char result[16];
    CC_MD5(UTF8URL, (CC_LONG)strlen(UTF8URL), result);
    
    return [NSString stringWithFormat:
            @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

+ (void)resetCacheForURL:(NSURL *)url
{
    [[self imageCache] removeCacheForKey:[self cacheKeyforURL:url]];
}

+ (void)clearImageCache
{
    [[self imageCache] clearCache];
}

@end
