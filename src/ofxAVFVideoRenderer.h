

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
    AVPlayer *player;
    AVPlayerItem *playerItem;
    AVPlayerLayer *playerLayer;
    AVAssetReader *assetReader;
    
    NSMutableArray * leftVolume;
    NSMutableArray * rightVolume;
    float maxVolume;
    
    CARenderer *layerRenderer;
    
    CGSize videoSize;
    CMTime videoDuration;
    
    BOOL loading;
    BOOL ready;
    BOOL deallocWhenReady;
    
    id periodicTimeObserver;
}
    @property (nonatomic, retain) AVPlayer *player;
    @property (nonatomic, retain) AVPlayerItem *playerItem;
    @property (nonatomic, retain) AVPlayerLayer *playerLayer;
    @property (nonatomic, retain) AVAssetReader *assetReader;
    @property (nonatomic, retain) CARenderer *layerRenderer;

    @property (nonatomic, retain) NSMutableArray * leftVolume;
    @property (nonatomic, retain) NSMutableArray * rightVolume;
    @property (nonatomic, assign) float maxVolume;

- (void) loadFile:(NSString *)filename;
- (void) play;
- (void) stop;
- (void) playerItemDidReachEnd:(NSNotification *) notification;
//- (void) update;
- (BOOL) isReady;
- (BOOL) isLoading;
- (void) render;

- (CGSize) getVideoSize;
- (CMTime) getVideoDuration;

@end
