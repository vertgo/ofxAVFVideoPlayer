#include "testApp.h"

//--------------------------------------------------------------
void testApp::setup()
{
    ofSetVerticalSync(true);
    ofBackground(0);
    
    video.loadMovie("test.mov");
    video.play();
    video.setLoopState(OF_LOOP_NORMAL);
}

//--------------------------------------------------------------
void testApp::update()
{
    video.update();
    if (video.isLoaded() && !image.isAllocated()) {
        image.allocate(video.getWidth(), video.getHeight(), OF_IMAGE_COLOR);
    }
    if (video.isFrameNew()) {
        image.setFromPixels(video.getPixelsRef());
    }
}

//--------------------------------------------------------------
void testApp::draw()
{
    video.draw(0, 0);
    image.draw(video.getWidth(), 0);
    
    // Draw a timeline at the bottom of the screen.
    ofNoFill();
    ofSetColor(255);
    ofRect(0, ofGetHeight(), ofGetWidth(), -100);
    float playheadX = video.getPosition() * ofGetWidth();
    ofLine(playheadX, ofGetHeight() - 100, playheadX, ofGetHeight());
    ofDrawBitmapString(ofToString(video.getCurrentTime()) + " / " + ofToString(video.getDuration()), playheadX + 10, ofGetHeight() - 80);
    ofDrawBitmapString(ofToString(video.getCurrentFrame()) + " / " + ofToString(video.getTotalNumFrames()), playheadX + 10, ofGetHeight() - 10);
    
    ofDrawBitmapString("Rate: " + ofToString(video.getSpeed()), 10, 20);
}

//--------------------------------------------------------------
void testApp::keyPressed(int key)
{
    switch (key) {
        case ' ':
            if (video.isPaused()) video.setPaused(false);
            else video.setPaused(true);
            break;
            
        case 'a':
            video.play();
            break;
            
        case 's':
            video.stop();
            break;
            
        case OF_KEY_UP:
            video.setSpeed(video.getSpeed() * 1.1);
            break;
            
        case OF_KEY_DOWN:
            video.setSpeed(video.getSpeed() * 0.9);
            break;
            
        default:
            break;
    }
}

//--------------------------------------------------------------
void testApp::keyReleased(int key){

}

//--------------------------------------------------------------
void testApp::mouseMoved(int x, int y){

}

//--------------------------------------------------------------
void testApp::mouseDragged(int x, int y, int button){

}

//--------------------------------------------------------------
void testApp::mousePressed(int x, int y, int button){

}

//--------------------------------------------------------------
void testApp::mouseReleased(int x, int y, int button){

}

//--------------------------------------------------------------
void testApp::windowResized(int w, int h){

}

//--------------------------------------------------------------
void testApp::gotMessage(ofMessage msg){

}

//--------------------------------------------------------------
void testApp::dragEvent(ofDragInfo dragInfo){ 

}
