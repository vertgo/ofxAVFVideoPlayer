//
//  ofxAVFVideoRenderer.m
//  AVFoundationTest
//
//  Created by Sam Kronick on 5/31/13.
//
//

#import "ofxAVFVideoRenderer.h"

@interface AVFVideoRenderer ()

- (NSDictionary *)pixelBufferAttributes;

@end

@implementation AVFVideoRenderer

@synthesize player = _player;
@synthesize playerItemVideoOutput = _playerItemVideoOutput;
@synthesize playerItem = _playerItem;

//@synthesize playerItem, playerLayer, assetReader, layerRenderer;

@synthesize useTexture;

@synthesize outputPlayheadPosition;
@synthesize outputDuration;
@synthesize outputMovieTime;
@synthesize outputMovieDidEnd;

#if __MAC_OS_X_VERSION_MIN_REQUIRED > MAC_OS_X_VERSION_10_7
@synthesize amplitudes, numAmplitudes;
#endif

int count = 0;

- (id)init
{
    self = [super init];
    if (self) {
        _player = [[AVPlayer alloc] init];
            
        amplitudes = [[NSMutableData data] retain];
    }
    return self;
}

- (NSDictionary *)pixelBufferAttributes
{
    // kCVPixelFormatType_32ARGB, kCVPixelFormatType_32BGRA, kCVPixelFormatType_422YpCbCr8
    return @{
             (NSString *)kCVPixelBufferOpenGLCompatibilityKey : [NSNumber numberWithBool:self.useTexture],
             (NSString *)kCVPixelBufferPixelFormatTypeKey     : [NSNumber numberWithInt:kCVPixelFormatType_32ARGB]  //[NSNumber numberWithInt:kCVPixelFormatType_422YpCbCr8]
            };
}

- (void) loadFile:(NSString *)filename
{
    loading = YES;
    ready = NO;
    audioReady = NO;
    deallocWhenReady = NO;
    
    useTexture = true;
    
    //NSURL *fileURL = [NSURL URLWithString:filename];
    NSURL *fileURL = [NSURL fileURLWithPath:[filename stringByStandardizingPath]];
    
    if (amplitudes) {
        [amplitudes setLength:0];
    }
    numAmplitudes = 0;
    
    NSLog(@"Trying to load %@", filename);
    
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:fileURL options:nil];
    NSString *tracksKey = @"tracks";
    
    [asset loadValuesAsynchronouslyForKeys:@[tracksKey] completionHandler: ^{
        static const NSString *ItemStatusContext;
        // Perform the following back on the main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
            // Check to see if the file loaded
            NSError *error;
            AVKeyValueStatus status = [asset statusOfValueForKey:tracksKey error:&error];
            
            if (status == AVKeyValueStatusLoaded) {
                // Asset metadata has been loaded. Set up the player
                
                // Extract the video track to get the video size
                AVAssetTrack *videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
                videoSize = [videoTrack naturalSize];
                videoDuration = asset.duration;
                
                self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
                [self.playerItem addObserver:self forKeyPath:@"status" options:0 context:&ItemStatusContext];
                
                // Notify this object when the player reaches the end
                // This allows us to loop the video
                [[NSNotificationCenter defaultCenter] addObserver:self
                                                         selector:@selector(playerItemDidReachEnd:)
                                                             name:AVPlayerItemDidPlayToEndTimeNotification
                                                           object:self.playerItem];

                [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
                
                // Create and attach video output. 10.8 Only!!!
                _playerItemVideoOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:[self pixelBufferAttributes]];
                if (self.playerItemVideoOutput) {
                    self.playerItemVideoOutput.suppressesPlayerRendering = YES;
                    //            [playerItemVideoOutput setDelegate:self queue:dispatch_get_main_queue()];
                    //            [playerItemVideoOutput requestNotificationOfMediaDataChangeWithAdvanceInterval:ADVANCE_INTERVAL_IN_SECONDS];
                }
                [[self.player currentItem] addOutput:self.playerItemVideoOutput];
                
                // Create CVOpenGLTextureCacheRef for optimal CVPixelBufferRef to GL texture conversion.
                if (self.useTexture && !_textureCache) {
                    CVReturn err = CVOpenGLTextureCacheCreate(kCFAllocatorDefault, NULL,
                                                              CGLGetCurrentContext(), CGLGetPixelFormat(CGLGetCurrentContext()),
                                                              NULL, &_textureCache);
                                                              //(CFDictionaryRef)ctxAttributes, &_textureCache);
                    if (err != noErr) {
                        NSLog(@"Error at CVOpenGLTextureCacheCreate %d", err);
//                        return;
                    }
                }
                
                
                
                
//                self.outputDuration = CMTimeGetSeconds([[player currentItem] duration]);
                
//                [self.player play];

                
//                self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
//                
//                self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
//                
//                self.layerRenderer = [CARenderer rendererWithCGLContext:CGLGetCurrentContext() options:nil];
//                self.layerRenderer.layer = playerLayer;
//                
//                // Video is centered on 0,0 for some reason so layer bounds have to start at -width/2,-height/2
//                self.layerRenderer.bounds = CGRectMake(-videoSize.width/2, -videoSize.height/2, videoSize.width, videoSize.height);
//                self.playerLayer.bounds = self.layerRenderer.bounds;



// EZ: Let's worry about this audio stuff later.
//#if __MAC_OS_X_VERSION_MIN_REQUIRED > MAC_OS_X_VERSION_10_7
//                NSArray *audioTracks = [asset tracksWithMediaType:AVMediaTypeAudio];
//                if ([audioTracks count] > 0) {
//                    AVAssetTrack *audioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
//
//                    NSError *error = nil;
//                    AVAssetReader *assetReader = [[AVAssetReader alloc] initWithAsset:asset error:&error];
//                    if (error != nil) {
//                        NSLog(@"Unable to create asset reader %@", [error localizedDescription]);
//                    }
//                    else if (audioTrack != nil) {
//                        // Read the audio track data
//                        NSMutableDictionary *bufferOptions = [NSMutableDictionary dictionary];
//                        [bufferOptions setObject:[NSNumber numberWithInt:kAudioFormatLinearPCM] forKey:AVFormatIDKey];
//                        [bufferOptions setObject:@44100 forKey:AVSampleRateKey];
//                        [bufferOptions setObject:@2 forKey:AVNumberOfChannelsKey];
////                        [bufferOptions setObject:[NSData dataWithBytes:&channelLayout length:sizeof(AudioChannelLayout)] forKey:AVChannelLayoutKey];
//                        [bufferOptions setObject:@32 forKey:AVLinearPCMBitDepthKey];
//                        [bufferOptions setObject:@NO forKey:AVLinearPCMIsBigEndianKey];
//                        [bufferOptions setObject:@YES forKey:AVLinearPCMIsFloatKey];
//                        [bufferOptions setObject:@NO forKey:AVLinearPCMIsNonInterleaved];
//                        [assetReader addOutput:[AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:audioTrack
//                                                                                          outputSettings:bufferOptions]];
//                        [assetReader startReading];
//                        
//                        count = 0;
//                    
//                        // Add a periodic time observer that will store the audio track data in a buffer that we can access later
//                        periodicTimeObserver = [player addPeriodicTimeObserverForInterval:CMTimeMake(1001, [audioTrack nominalFrameRate] * 1001)
//                                                                                    queue:dispatch_queue_create("eventQueue", NULL)
//                                                                               usingBlock:^(CMTime time) {
//                                                                                   if ([assetReader status] == AVAssetReaderStatusCompleted) {
//                                                                                       // Got all the data we need, kill this block.
//                                                                                       [player removeTimeObserver:periodicTimeObserver];
//                                                                                       
//                                                                                       numAmplitudes = [amplitudes length] / sizeof(float);
//                                                                                       audioReady = YES;
//                                                                                       
//                                                                                       return;
//                                                                                   }
//                                                                                   
//                                                                                   if ([assetReader status] == AVAssetReaderStatusReading) {
//                                                                                       AVAssetReaderTrackOutput *output = [[assetReader outputs] objectAtIndex:0];
//                                                                                       CMSampleBufferRef sampleBuffer = [output copyNextSampleBuffer];
//                                                                                       
//                                                                                       while (sampleBuffer != NULL) {
//                                                                                           sampleBuffer = [output copyNextSampleBuffer];
//                                                                                           
//                                                                                           if (sampleBuffer == NULL)
//                                                                                               continue;
//                                                                                           
//                                                                                           CMBlockBufferRef buffer = CMSampleBufferGetDataBuffer(sampleBuffer);
//                                                                                           
//                                                                                           size_t lengthAtOffset;
//                                                                                           size_t totalLength;
//                                                                                           char* data;
//                                                                                           
//                                                                                           if (CMBlockBufferGetDataPointer(buffer, 0, &lengthAtOffset, &totalLength, &data) != noErr) {
//                                                                                               NSLog(@"error!");
//                                                                                               break;
//                                                                                           }
//                                                                                           
//                                                                                           CMItemCount numSamplesInBuffer = CMSampleBufferGetNumSamples(sampleBuffer);
//                                                                                           
//                                                                                           AudioBufferList audioBufferList;
//                                                                                           
//                                                                                           CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer,
//                                                                                                                                                   NULL,
//                                                                                                                                                   &audioBufferList,
//                                                                                                                                                   sizeof(audioBufferList),
//                                                                                                                                                   NULL,
//                                                                                                                                                   NULL,
//                                                                                                                                                   kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment,  // pass in something else
//                                                                                                                                                   &buffer);
//                                                                                           
//                                                                                           for (int bufferCount = 0; bufferCount < audioBufferList.mNumberBuffers; bufferCount++) {
//                                                                                               [amplitudes appendBytes:audioBufferList.mBuffers[bufferCount].mData
//                                                                                                                length:audioBufferList.mBuffers[bufferCount].mDataByteSize];
//                                                                                           }
//                                                                                                                                                                                      
//                                                                                           CFRelease(buffer);
//                                                                                           CFRelease(sampleBuffer);
//                                                                                       }
//                                                                                   }
//                                                                               }];
//                    }
//                }
//#endif
                ready = YES;
                loading = NO;
            }
            else {
                loading = NO;
                ready = NO;
                NSLog(@"There was an error loading the file: %@", error);
            }
            
            // If dealloc is called immediately after loadFile, we have to defer releasing properties
            if(deallocWhenReady) [self dealloc];
            [pool release];
        });
    }];
}

- (void) dealloc
{
    if (loading) {
        deallocWhenReady = YES;
    }
    else {
        [self stop];
        
        // SK: Releasing the CARenderer is slow for some reason
        //     It will freeze the main thread for a few dozen mS.
        //     If you're swapping in and out videos a lot, the loadFile:
        //     method should be re-written to just re-use and re-size
        //     these layers/objects rather than releasing and reallocating
        //     them every time a new file is needed.
        
//        if(self.layerRenderer) [self.layerRenderer release];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        if(self.playerItem) [self.playerItem removeObserver:self forKeyPath:@"status"];
        
//        if(self.player) [self.player release];
//        if(self.playerItem) [self.playerItem release];
//        if(self.playerLayer) [self.playerLayer release];
        
        [_player release];
        _player = nil;
        
//        dispatch_sync(playerVideoOutputQueue, ^{
//            [playerItemVideoOutput setDelegate:nil queue:NULL];
//        });
        
        [_playerItemVideoOutput release];
        _playerItemVideoOutput = nil;
        
        if (_textureCache != NULL) {
			CVOpenGLTextureCacheRelease(_textureCache);
			_textureCache = NULL;
		}
        if (_latestTextureFrame != NULL) {
			CVOpenGLTextureRelease(_latestTextureFrame);
			_latestTextureFrame = NULL;
		}
		if (_latestPixelFrame != NULL) {
			CVPixelBufferRelease(_latestPixelFrame);
			_latestPixelFrame = NULL;
		}
        
        if (amplitudes) [amplitudes release];
        numAmplitudes = 0;
        
        if (!deallocWhenReady) [super dealloc];
    }
}

- (BOOL) isLoading { return loading; }
- (BOOL) isReady { return ready; }
- (BOOL) isAudioReady { return audioReady; }
- (BOOL) isPlaying { return self.player.rate != 0; }
- (CGSize) getVideoSize {
    return videoSize;
}

- (CMTime) getVideoDuration {
    return videoDuration;
}

- (void) play {
    [self.player play];
}

- (void) stop {
    [self.player pause];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
}

- (void) playerItemDidReachEnd:(NSNotification *) notification {
    [self.player seekToTime:kCMTimeZero];
    // if(loop)
    //[self.player play];
}

- (void)update
{
//    CMTime outputItemTime = kCMTimeInvalid;
//	
//	// Calculate the nextVsync time which is when the screen will be refreshed next.
//	CFTimeInterval nextVSync = ([sender timestamp] + [sender duration]);
//	
//	outputItemTime = [[self videoOutput] itemTimeForHostTime:nextVSync];
//	
//	if ([[self videoOutput] hasNewPixelBufferForItemTime:outputItemTime]) {
//		CVPixelBufferRef pixelBuffer = NULL;
//		pixelBuffer = [[self videoOutput] copyPixelBufferForItemTime:outputItemTime itemTimeForDisplay:NULL];
//		
//		[[self playerView] displayPixelBuffer:pixelBuffer];
//	}
    
    
    // check our video output for new frames
    CMTime outputItemTime = [self.playerItemVideoOutput itemTimeForHostTime:CACurrentMediaTime()];
    if ([self.playerItemVideoOutput hasNewPixelBufferForItemTime:outputItemTime]) {
        // Get pixels.
        if (_latestPixelFrame != NULL) {
            CVPixelBufferRelease(_latestPixelFrame);
            _latestPixelFrame = NULL;
        }
        _latestPixelFrame = [self.playerItemVideoOutput copyPixelBufferForItemTime:outputItemTime
                                                                itemTimeForDisplay:NULL];
        
        if (self.useTexture) {
            // Create GL texture.
            if (_latestTextureFrame != NULL) {
                CVOpenGLTextureRelease(_latestTextureFrame);
                _latestTextureFrame = NULL;
                CVOpenGLTextureCacheFlush(_textureCache, 0);
            }
            
            CVReturn err = CVOpenGLTextureCacheCreateTextureFromImage(NULL, _textureCache, _latestPixelFrame, NULL, &_latestTextureFrame);
            if (err != noErr) {
                NSLog(@"Error creating OpenGL texture %d", err);
            }
        }
        
        // create new output image provider - retains the pixel buffer for us
//        v002CVPixelBufferImageProvider *output = [[v002CVPixelBufferImageProvider alloc] initWithPixelBuffer:pixBuff isFlipped:CVImageBufferIsFlipped(pixBuff) shouldColorMatch:self.inputColorCorrection];
        
//        self.outputImage = output;
        
//        [output release];
//        CVBufferRelease(pixBuff);
        
        // Update time.
        double currentTime = CMTimeGetSeconds([[self.player currentItem] currentTime]);
        double duration = CMTimeGetSeconds([[self.player currentItem] duration]);
        
        self.outputMovieTime = currentTime;
        self.outputPlayheadPosition = currentTime / duration;
        
        NSLog(@"Curr time is %f, curr playhead is %f", self.outputMovieTime, self.outputPlayheadPosition);
    }
}

- (void) render {
    // From https://qt.gitorious.org/qt/qtmultimedia/blobs/700b4cdf42335ad02ff308cddbfc37b8d49a1e71/src/plugins/avfoundation/mediaplayer/avfvideoframerenderer.mm
    
    glPushAttrib(GL_ENABLE_BIT);
    glDisable(GL_DEPTH_TEST);
    
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glViewport(0, 0, videoSize.width, videoSize.height);
    
    glMatrixMode(GL_PROJECTION);
    glPushMatrix();
    glLoadIdentity();
    
    glOrtho(0.0f, videoSize.width, videoSize.height, 0.0f, 0.0f, 1.0f);
    
    glMatrixMode(GL_MODELVIEW);
    glPushMatrix();
    glLoadIdentity();
    
    glTranslatef(videoSize.width/2,videoSize.height/2,0);
    
    [layerRenderer beginFrameAtTime:CACurrentMediaTime() timeStamp:NULL];
    [layerRenderer addUpdateRect:layerRenderer.layer.bounds];
    [layerRenderer render];
    [layerRenderer endFrame];
    
    glMatrixMode(GL_MODELVIEW);
    glPopMatrix();
    glMatrixMode(GL_PROJECTION);
    glPopMatrix();
    
    glPopAttrib();
    
    glFinish(); //Rendering needs to be done before passing texture to video frame
}

#pragma mark - GL Texture

//--------------------------------------------------------------
- (BOOL)textureAllocated
{
	return self.useTexture && _latestTextureFrame != NULL;
}

//--------------------------------------------------------------
- (GLuint)textureID
{
	@synchronized(self) {
		return CVOpenGLTextureGetName(_latestTextureFrame);
	}
}

//--------------------------------------------------------------
- (GLenum)textureTarget
{
    return CVOpenGLTextureGetTarget(_latestTextureFrame);
}

//--------------------------------------------------------------
- (void)bindTexture
{
	if (!self.textureAllocated) return;
    
	GLuint texID = [self textureID];
	GLenum target = [self textureTarget];
	
	glEnable(target);
	glBindTexture(target, texID);
}

//--------------------------------------------------------------
- (void) unbindTexture
{
	if (!self.textureAllocated) return;
	
	GLenum target = [self textureTarget];
	glDisable(target);
}

@end
