

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

@interface AVFVideoRenderer : NSObject
{
    AVPlayer * _player;
    AVPlayerItemVideoOutput * _playerItemVideoOutput;
    AVPlayerItem * _playerItem;
//    AVPlayerLayer *playerLayer;
//    AVAssetReader *assetReader;
    
    CVOpenGLTextureCacheRef _textureCache;
	CVOpenGLTextureRef _latestTextureFrame;
	CVPixelBufferRef _latestPixelFrame;
    
    BOOL useTexture;
    BOOL frameIsNew;
    
    double outputPlayheadPosition;
    double outputDuration;
    double outputMovieTime;
    BOOL outputMovieDidEnd;
    
    NSMutableData *amplitudes;
    int numAmplitudes;
    
    CARenderer *layerRenderer;
    
    CGSize videoSize;
    CMTime videoDuration;
    
    BOOL loading;
    BOOL ready;
    BOOL audioReady;
    BOOL deallocWhenReady;
	
    id periodicTimeObserver;
}

@property (nonatomic, retain) AVPlayer *player;
@property (nonatomic, retain) AVPlayerItemVideoOutput *playerItemVideoOutput;
@property (nonatomic, retain) AVPlayerItem *playerItem;
//@property (nonatomic, retain) AVPlayerLayer *playerLayer;
//@property (nonatomic, retain) AVAssetReader *assetReader;
//@property (nonatomic, retain) CARenderer *layerRenderer;

@property (nonatomic, readonly) BOOL textureAllocated;
@property (nonatomic, readonly) GLuint textureID;
@property (nonatomic, readonly) GLenum textureTarget;

- (void)bindTexture;
- (void)unbindTexture;

@property (nonatomic, readonly) BOOL useTexture;

@property (nonatomic, assign) double outputPlayheadPosition;
@property (nonatomic, assign) double outputDuration;
@property (nonatomic, assign) double outputMovieTime;
@property (nonatomic, assign) BOOL outputMovieDidEnd;

#if __MAC_OS_X_VERSION_MIN_REQUIRED > MAC_OS_X_VERSION_10_7
@property (nonatomic, retain) NSMutableData *amplitudes;
@property (nonatomic, assign) int numAmplitudes;
#endif



- (void) loadFile:(NSString *)filename;
- (void) play;
- (void) stop;
- (void) playerItemDidReachEnd:(NSNotification *) notification;
//- (void) update;
- (BOOL) isReady;
- (BOOL) isAudioReady;
- (BOOL) isLoading;
- (BOOL) isPlaying;

- (void)update;

- (void) render;

//- (void)postProcessAmplitude:(float)damping;

- (CGSize) getVideoSize;
- (CMTime) getVideoDuration;

@end
