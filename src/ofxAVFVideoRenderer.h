

//
//  ofxAVFVideoRenderer.h
//  AVFoundationTest
//
//  Created by Sam Kronick on 5/31/13.
//
//


#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import <AVFoundation/AVFoundation.h>
#import <OpenGL/OpenGL.h>

#ifndef NEW_SCHOOL
#define NEW_SCHOOL (__MAC_OS_X_VERSION_MIN_REQUIRED > MAC_OS_X_VERSION_10_7)
#endif

@interface AVFVideoRenderer : NSObject
{
    AVPlayer * _player;
    AVPlayerItemVideoOutput * _playerItemVideoOutput;
    AVPlayerItem * _playerItem;
    
#if NEW_SCHOOL
    CVOpenGLTextureCacheRef _textureCache;
	CVOpenGLTextureRef _latestTextureFrame;
	CVPixelBufferRef _latestPixelFrame;
#else
    AVPlayerLayer * _playerLayer;
    CARenderer * _layerRenderer;
#endif
    
	BOOL _useTexture;
	BOOL _useAlpha;
    
    CGSize _videoSize;
    
    CMTime _currentTime;
    CMTime _duration;
    double _frameRate;
    double _playbackRate;
    
    BOOL _bLoading;
    BOOL _bLoaded;
    BOOL _bAudioLoaded;
    BOOL _bPaused;
    BOOL _bMovieDone;
    
    BOOL _bDeallocWhenLoaded;
	
#if NEW_SCHOOL
    NSMutableData *_amplitudes;
    int _numAmplitudes;
    id _periodicTimeObserver;
#endif
}

@property (nonatomic, retain) AVPlayer *player;
@property (nonatomic, retain) AVPlayerItemVideoOutput *playerItemVideoOutput;
@property (nonatomic, retain) AVPlayerItem *playerItem;

@property (nonatomic, assign, readonly) double width;
@property (nonatomic, assign, readonly) double height;

@property (nonatomic, assign, readonly, getter = isLoading) BOOL bLoading;
@property (nonatomic, assign, readonly, getter = isLoaded) BOOL bLoaded;
#if NEW_SCHOOL
@property (nonatomic, assign, readonly, getter = isAudioLoaded) BOOL bAudioLoaded;
#endif
@property (nonatomic, assign, getter = isPaused, setter = setPaused:) BOOL bPaused;
@property (nonatomic, assign, readonly, getter = isMovieDone) BOOL bMovieDone;
@property (nonatomic, assign, readonly) BOOL isPlaying;

@property (nonatomic, readonly) BOOL useAlpha;
@property (nonatomic, readonly) BOOL useTexture;

#if NEW_SCHOOL
@property (nonatomic, readonly) BOOL textureAllocated;
@property (nonatomic, readonly) GLuint textureID;
@property (nonatomic, readonly) GLenum textureTarget;
#else
@property (nonatomic, retain) AVPlayerLayer *playerLayer;
@property (nonatomic, retain) CARenderer *layerRenderer;
#endif

@property (nonatomic, assign, readonly) double frameRate;
@property (nonatomic, assign, readonly) double duration;
@property (nonatomic, assign, readonly) int totalFrames;
@property (nonatomic, assign) double currentTime;
@property (nonatomic, assign) int currentFrame;
@property (nonatomic, assign) double position;
@property (nonatomic, assign) double playbackRate;

#if NEW_SCHOOL
@property (nonatomic, retain, readonly) NSMutableData *amplitudes;
@property (nonatomic, assign, readonly) int numAmplitudes;
#endif

- (void)loadFile:(NSString *)filename;

- (void)play;
- (void)stop;

- (BOOL)update;

#if NEW_SCHOOL
- (void)bindTexture;
- (void)unbindTexture;
- (void)pixels:(unsigned char *)outbuf;
#else
- (void)render;
#endif

@end
