//
//  ofxAVFoundationvVideoPlayer.mm
//  AVFoundationTest
//
//  Created by Sam Kronick on 5/31/13.
//
//

#include "ofxAVFVideoPlayer.h"
#include "Poco/String.h"

//--------------------------------------------------------------
ofxAVFVideoPlayer::ofxAVFVideoPlayer()
{
    moviePlayer = NULL;
	bNewFrame = false;
    bPaused = true;
	duration = 0.0f;
    speed = 1.0f;
	
    scrubToTime = 0.0;
    bInitialized = false;
    
    pixelFormat = OF_PIXELS_RGB;
    currentLoopState = OF_LOOP_NORMAL;
	
	ofAddListener(ofEvents().exit, this, &ofxAVFVideoPlayer::exit);
}

//--------------------------------------------------------------
void ofxAVFVideoPlayer::exit(ofEventArgs& args)
{
	close();
}

//--------------------------------------------------------------
ofxAVFVideoPlayer::~ofxAVFVideoPlayer()
{
	close();
}

//--------------------------------------------------------------
bool ofxAVFVideoPlayer::loadMovie(string path)
{
    bInitialized = false;
	
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    moviePlayer = [[AVFVideoRenderer alloc] init];
    bool isURL = false;
	
    if (Poco::icompare(path.substr(0,7), "http://")  == 0 ||
        Poco::icompare(path.substr(0,8), "https://") == 0 ||
        Poco::icompare(path.substr(0,7), "rtsp://")  == 0) {
        isURL = true;
    }
    else {
        path = ofToDataPath(path, false);
    }
    
    [moviePlayer loadFile:[NSString stringWithUTF8String:path.c_str()]];
    
    bShouldPlay = false;
	
    [pool release];
    
    return true;
}

//--------------------------------------------------------------
void ofxAVFVideoPlayer::closeMovie()
{
    close();
}

//--------------------------------------------------------------
void ofxAVFVideoPlayer::close()
{
    pixels.clear();
    
    if (moviePlayer) {
        [moviePlayer release];
        moviePlayer = NULL;
    }
    
    bInitialized = false;
}

//--------------------------------------------------------------
void ofxAVFVideoPlayer::idleMovie()
{
    update();
}

//--------------------------------------------------------------
void ofxAVFVideoPlayer::update()
{
    if (!moviePlayer) return;
    
    if ([moviePlayer isLoaded]) {
        if (!bInitialized) {
            // Create the FBO.
#if NEW_SCHOOL
            reallocatePixels();
#else
            fbo.allocate(moviePlayer.width, moviePlayer.height);
#endif
            bInitialized = true;

            if (scrubToTime != 0.0f) {
				setTime(scrubToTime);
				scrubToTime = 0.0f;
			}
            
			if (bShouldPlay){
				play();
				bShouldPlay = false;
			}
        }
        
#if NEW_SCHOOL
        bNewFrame = [moviePlayer update];
#else
        // Render movie into FBO so we can get a texture
        fbo.begin();
        [moviePlayer render];
        fbo.end();
        bNewFrame = true;
#endif
        bHavePixelsChanged = bNewFrame;
    }
    else {
        ofLogNotice("ofxAVFVideoPlayer::update()") << "Movie player not ready";
    }
}

//--------------------------------------------------------------
void ofxAVFVideoPlayer::play()
{
	if (bInitialized) {
        ofLogVerbose("ofxAVFVideoPlayer::play()") << "Initialized and playing at time " << getCurrentTime();
		[moviePlayer play];
	}
	else {
		bShouldPlay = true;
	}
}

//--------------------------------------------------------------
void ofxAVFVideoPlayer::stop()
{
    [moviePlayer stop];
}

//--------------------------------------------------------------
bool ofxAVFVideoPlayer::isFrameNew()
{
    return bNewFrame;
}

#if NEW_SCHOOL
//--------------------------------------------------------------
float ofxAVFVideoPlayer::getAmplitude(int channel)
{
    return getAmplitudeAt(getPosition(), channel);
}

//--------------------------------------------------------------
float ofxAVFVideoPlayer::getAmplitudeAt(float pos, int channel)
{
    pos = ofClamp(pos, 0, 1);
    channel = ofClamp(channel, 0, 1);
    
    if (!moviePlayer || ![moviePlayer isAudioLoaded] || [moviePlayer numAmplitudes] == 0 || !bInitialized) {
        return 0;
    }
    
    int idx = (int)(pos * ([moviePlayer numAmplitudes] - 2));
    
    // Make sure the index is pointing at the right channel
    // EZ: I know this is ghetto, but it works...
    if (idx % 2 == 0 && channel == 1) {
        ++idx;
    }
    else if (idx % 2 == 1 && channel == 0) {
        --idx;
    }

    float amp;
    [moviePlayer.amplitudes getBytes:&amp range:NSMakeRange(idx * sizeof(float), sizeof(float))];
    return amp;
}

//--------------------------------------------------------------
int ofxAVFVideoPlayer::getNumAmplitudes()
{
    return [moviePlayer numAmplitudes];
}

//--------------------------------------------------------------
float * ofxAVFVideoPlayer::getAllAmplitudes()
{
    return (float *)[moviePlayer.amplitudes bytes];
}
#endif

//--------------------------------------------------------------
unsigned char * ofxAVFVideoPlayer::getPixels()
{
#if NEW_SCHOOL
    return getPixelsRef().getPixels();
#else
    if (!moviePlayer || ![moviePlayer isLoaded] || !bInitialized) return NULL;
    
    if (bHavePixelsChanged) {
        fbo.readToPixels(pixels);
        bHavePixelsChanged = false; // Don't read pixels until next update() is called
    }
    return pixels.getPixels();
#endif
}

//--------------------------------------------------------------
ofPixelsRef ofxAVFVideoPlayer::getPixelsRef()
{
#if NEW_SCHOOL
    if (isLoaded()) {
        // Don't get the pixels every frame if it hasn't updated
        if (bHavePixelsChanged) {
            [moviePlayer pixels:pixels.getPixels()];
            bHavePixelsChanged = false;
        }
	}
    else {
        ofLogError("ofxAVFVideoPlayer::getPixelsRef()") << "Returning pixels that may be unallocated. Make sure to initialize the video player before calling getPixelsRef.";
    }
#else
    getPixels();
#endif
    
	return pixels;
}

//--------------------------------------------------------------
ofTexture* ofxAVFVideoPlayer::getTexture()
{
#if NEW_SCHOOL
    if (moviePlayer.textureAllocated) {
		updateTexture();
        return &tex;
	}

    return NULL;
#else
    if (!moviePlayer || ![moviePlayer isLoaded] || !bInitialized) return NULL;
    
    return &fbo.getTextureReference();
#endif
}

//--------------------------------------------------------------
ofTexture& ofxAVFVideoPlayer::getTextureReference()
{
#if NEW_SCHOOL
    getTexture();
    return tex;
#else
    if (!moviePlayer || ![moviePlayer isLoaded] || !bInitialized) return;
    return fbo.getTextureReference();
#endif
}

//--------------------------------------------------------------
bool ofxAVFVideoPlayer::isLoading()
{
    return moviePlayer && [moviePlayer isLoading];
}

//--------------------------------------------------------------
bool ofxAVFVideoPlayer::isLoaded()
{
    return bInitialized;
}

#if NEW_SCHOOL
//--------------------------------------------------------------
bool ofxAVFVideoPlayer::isAudioLoaded()
{
    return moviePlayer && [moviePlayer isAudioLoaded];
}
#endif

//--------------------------------------------------------------
bool ofxAVFVideoPlayer::errorLoading()
{
    if (!moviePlayer) return false;
    
    // Error if movie player is not loading and is not ready.
    return ![moviePlayer isLoading] && ![moviePlayer isLoaded];
}

//--------------------------------------------------------------
bool ofxAVFVideoPlayer::isPlaying()
{
    return moviePlayer && [moviePlayer isPlaying];
}

//--------------------------------------------------------------
bool ofxAVFVideoPlayer::getIsMovieDone()
{
    return moviePlayer.isMovieDone;
}

//--------------------------------------------------------------
float ofxAVFVideoPlayer::getPosition()
{
    return moviePlayer.position;
}

//--------------------------------------------------------------
float ofxAVFVideoPlayer::getCurrentTime()
{
    return moviePlayer.currentTime;
}

//--------------------------------------------------------------
int ofxAVFVideoPlayer::getCurrentFrame()
{
    return moviePlayer.currentFrame;
}

//--------------------------------------------------------------
float ofxAVFVideoPlayer::getDuration()
{
    return moviePlayer.duration;
}

//--------------------------------------------------------------
int ofxAVFVideoPlayer::getTotalNumFrames()
{
    return moviePlayer.totalFrames;
}

//--------------------------------------------------------------
bool ofxAVFVideoPlayer::isPaused()
{
    return moviePlayer && [moviePlayer isPaused];
}

//--------------------------------------------------------------
float ofxAVFVideoPlayer::getSpeed()
{
    if (moviePlayer) {
        return moviePlayer.playbackRate;
    }
    
    return 0;
}

//--------------------------------------------------------------
ofLoopType ofxAVFVideoPlayer::getLoopState()
{
    if (moviePlayer && [moviePlayer loops])
        return OF_LOOP_NORMAL;
    
	return OF_LOOP_NONE;
}

//--------------------------------------------------------------
void ofxAVFVideoPlayer::setPosition(float pct)
{
    [moviePlayer setPosition:pct];
}

//--------------------------------------------------------------
void ofxAVFVideoPlayer::setTime(float position)
{
	if (![moviePlayer isLoaded]) {
		ofLogNotice("ofxAVFVideoPlayer::setCurrentTime()") << "Video player not ready, declaring to scrub to time " << scrubToTime;
		scrubToTime = position;
	}
	else {
        [moviePlayer setCurrentTime:position];
	}
}

//--------------------------------------------------------------
void ofxAVFVideoPlayer::setFrame(int frame)
{
    [moviePlayer setCurrentFrame:frame];
}

void ofxAVFVideoPlayer::setVolume(float volume) {
    moviePlayer.player.volume = volume;
}

void ofxAVFVideoPlayer::setBalance(float balance) {
    
}

//--------------------------------------------------------------
void ofxAVFVideoPlayer::setPaused(bool bPaused)
{
    [moviePlayer setPaused:bPaused];
}

//--------------------------------------------------------------
void ofxAVFVideoPlayer::setLoopState(ofLoopType state)
{
    if (moviePlayer) {
        [moviePlayer setLoops:(state == OF_LOOP_NORMAL)];
    }
    
    if (state == OF_LOOP_PALINDROME) {
        ofLogWarning("ofxAVFVideoPlayer::setLoopState") << "No palindrome yet, sorry!";
    }
}

//--------------------------------------------------------------
void ofxAVFVideoPlayer::setSpeed(float speed)
{
    [moviePlayer setPlaybackRate:speed];
}

bool ofxAVFVideoPlayer::setPixelFormat(ofPixelFormat pixelFormat) {
    
}

ofPixelFormat ofxAVFVideoPlayer::getPixelFormat() {
    
}

//--------------------------------------------------------------
void ofxAVFVideoPlayer::draw(float x, float y)
{
    if (!bInitialized) return;
    
#if NEW_SCHOOL
    draw(x, y, getWidth(), getHeight());
#else
    fbo.draw(x, y);
#endif
}

//--------------------------------------------------------------
void ofxAVFVideoPlayer::draw(float x, float y, float w, float h)
{
    if (!bInitialized) return;
    
#if NEW_SCHOOL
    updateTexture();
	tex.draw(x, y, w, h);
#else
    fbo.draw(x, y, w, h);
#endif
}

//--------------------------------------------------------------
float ofxAVFVideoPlayer::getWidth()
{
    return moviePlayer.width;
}

//--------------------------------------------------------------
float ofxAVFVideoPlayer::getHeight()
{
    return moviePlayer.height;
}

void ofxAVFVideoPlayer::firstFrame() {
    
}

void ofxAVFVideoPlayer::nextFrame() {
    
}

void ofxAVFVideoPlayer::previousFrame() {
    
}

#if NEW_SCHOOL
//--------------------------------------------------------------
void ofxAVFVideoPlayer::updateTexture()
{
    if (moviePlayer.textureAllocated) {
		tex.setUseExternalTextureID(moviePlayer.textureID);
		
		ofTextureData& data = tex.getTextureData();
		data.textureTarget = moviePlayer.textureTarget;
		data.width = getWidth();
		data.height = getHeight();
		data.tex_w = getWidth();
		data.tex_h = getHeight();
		data.tex_t = getWidth();
		data.tex_u = getHeight();
	}
}

//--------------------------------------------------------------
void ofxAVFVideoPlayer::reallocatePixels()
{
    if (pixelFormat == OF_PIXELS_RGBA) {
        pixels.allocate(getWidth(), getHeight(), OF_IMAGE_COLOR_ALPHA);
    }
    else {
        pixels.allocate(getWidth(), getHeight(), OF_IMAGE_COLOR);
    }
}
#endif
