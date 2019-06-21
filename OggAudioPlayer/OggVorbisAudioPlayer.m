//
//  OggVorbisAudioPlayer.m
//  OggAudioPlayer
//
//  Created by Enter on 2019/6/20.
//  Copyright © 2019 Enter. All rights reserved.
//
#import <AudioToolbox/AudioToolbox.h>
#import "OggAudioDecoder.h"
#import "OggVorbisAudioPlayer.h"

#define OGG_BUFFER_COUNT 3
typedef enum OggAudioPlayStateTag
{
    OggAudioPlayerStateStopped,
    OggAudioPlayerStatePrepared,
    OggAudioPlayerStatePlaying,
    OggAudioPlayerStatePaused,
    OggAudioPlayerStateStopping
    
} OggAudioPlayerState;

@interface OggVorbisAudioPlayer ()
{
@private
    AudioQueueRef mQueue;
    AudioQueueBufferRef mBuffers[OGG_BUFFER_COUNT];
    BOOL mStopping;
    NSTimeInterval mQueueStartTime;
}
/**
 * @brief Queries the value of the Audio Queue's kAudioQueueProperty_IsRunning property.
 */
- (UInt32)queryIsRunning;
/**
 * @brief Reads data from the audio source and enqueues it on the audio queue.
 */
- (void)readBuffer:(AudioQueueBufferRef)buffer;
/**
 * @brief Stops playback
 * @param immediate if YES playback stops immediately, otherwise playback stops after all enqueued buffers
 * have finished playing.
 */
- (BOOL)stop:(BOOL)immediate;
/**
 * @brief YES if the player is playing, NO otherwise.
 */
@property (readwrite, getter=isPlaying) BOOL playing;
/**
 * @brief The decoder associated with this player.
 */
@property (readonly, strong) id<OggAudioDecoder> decoder;
/**
 * @brief The current player state.
 */
@property (nonatomic, assign) OggAudioPlayerState state;
@end

@implementation OggVorbisAudioPlayer
@dynamic currentTime;
@dynamic numberOfChannels;
@dynamic duration;
@synthesize playing = mPlaying;
@synthesize decoder = mDecoder;
@synthesize state = mState;

// MARK: - Static Callbacks
static void OggOutputCallback(void *                  inUserData,
                              AudioQueueRef           inAQ,
                              AudioQueueBufferRef     inCompleteAQBuffer)
{
    OggVorbisAudioPlayer* pPlayer = (__bridge OggVorbisAudioPlayer*)inUserData;
    [pPlayer readBuffer:inCompleteAQBuffer];
}

static void OggPropertyListener(void* inUserData,
                                AudioQueueRef inAQ,
                                AudioQueuePropertyID inID)
{
    OggVorbisAudioPlayer* pPlayer = (__bridge OggVorbisAudioPlayer*)inUserData;
    if(inID == kAudioQueueProperty_IsRunning)
    {
        UInt32 isRunning = [pPlayer queryIsRunning];
        NSLog(@"isRunning = %u", (unsigned int)isRunning);
        BOOL bDidFinish = (pPlayer.playing && !isRunning);
        pPlayer.playing = isRunning ? YES : NO;
        if(bDidFinish)
        {
            [pPlayer.delegate audioPlayerDidFinishPlaying:pPlayer
                                             successfully:YES];
            /*
             * To match AVPlayer's behavior we need to reset the file.
             */
            pPlayer.currentTime = 0;
        }
        if(!isRunning)
            pPlayer.state = OggAudioPlayerStateStopped;
    }
    
}


- (id)initWithDecoder:(id<OggAudioDecoder>)decoder error:(NSError *__autoreleasing *)error
{
    NSParameterAssert(decoder);
    if(self = [super init])
    {
        mDecoder = decoder;
        AudioStreamBasicDescription dataFormat = decoder.dataFormat;
        OSStatus status = AudioQueueNewOutput(&dataFormat, OggOutputCallback,
                                              (__bridge void*)self,
                                              CFRunLoopGetCurrent(),
                                              kCFRunLoopCommonModes,
                                              0,
                                              &mQueue);
        NSAssert(status == noErr, @"Audio queue creation was successful.");
        AudioQueueSetParameter(mQueue, kAudioQueueParam_Volume, 1.0);
        status = AudioQueueAddPropertyListener(mQueue, kAudioQueueProperty_IsRunning,
                                               OggPropertyListener, (__bridge void*)self);
        
        for(int i = 0; i < OGG_BUFFER_COUNT; ++i)
        {
            UInt32 bufferSize = 128 * 1024;
            status = AudioQueueAllocateBuffer(mQueue, bufferSize, &mBuffers[i]);
            if(status != noErr)
            {
                if(*error)
                {
                    *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
                }
                AudioQueueDispose(mQueue, true);
                mQueue = 0;
                return nil;
            }
            
        }
    }
    mState = OggAudioPlayerStateStopped;
    mQueueStartTime = 0.0;
    return self;
}

- (BOOL)prepareToPlay
{
    for(int i = 0; i < OGG_BUFFER_COUNT; ++i)
    {
        [self readBuffer:mBuffers[i]];
    }
    self.state = OggAudioPlayerStatePrepared;
    return YES;
}
- (BOOL)play
{
    switch(self.state)
    {
        case OggAudioPlayerStatePlaying:
            return NO;
        case OggAudioPlayerStatePaused:
        case OggAudioPlayerStatePrepared:
            break;
        default:
            [self prepareToPlay];
    }
    OSStatus osStatus = AudioQueueStart(mQueue, NULL);
    NSAssert(osStatus == noErr, @"AudioQueueStart failed");
    self.state = OggAudioPlayerStatePlaying;
    self.playing = YES;
    return (osStatus == noErr);
    
}
- (BOOL)pause
{
    if(self.state != OggAudioPlayerStatePlaying) return NO;
    OSStatus osStatus = AudioQueuePause(mQueue);
    NSAssert(osStatus == noErr, @"AudioQueuePause failed");
    self.state = OggAudioPlayerStatePaused;
    return (osStatus == noErr);
    
    
}

- (BOOL)stop
{
    return [self stop:YES];
}

- (BOOL)stop:(BOOL)immediate
{
    self.state = OggAudioPlayerStateStopping;
    OSStatus osStatus = AudioQueueStop(mQueue, immediate);
    
    NSAssert(osStatus == noErr, @"AudioQueueStop failed");
    return (osStatus == noErr);
}

- (void)readBuffer:(AudioQueueBufferRef)buffer
{
    if(self.state == OggAudioPlayerStateStopping)
        return;
    
    NSAssert(self.decoder, @"self.decoder is valid.");
    if([self.decoder readBuffer:buffer])
    {
        OSStatus status = AudioQueueEnqueueBuffer(mQueue, buffer, 0, 0);
        if(status != noErr)
        {
            NSLog(@"Error: %s status=%d", __PRETTY_FUNCTION__, (int)status);
        }
    }
    else
    {
        /*
         * Signal to the audio queue that we have run out of data,
         * but set the immediate flag to false so that playback of
         * currently enqueued buffers completes.
         */
        self.state = OggAudioPlayerStateStopping;
        Boolean immediate = false;
        AudioQueueStop(mQueue, immediate);
    }
}

// MARK: - Properties

- (UInt32)queryIsRunning
{
    UInt32 oRunning = 0;
    UInt32 ioSize = sizeof(oRunning);
    OSStatus result = AudioQueueGetProperty(mQueue, kAudioQueueProperty_IsRunning, &oRunning, &ioSize);
    return oRunning;
}
- (NSTimeInterval)duration
{
    NSTimeInterval duration = mDecoder.duration;
    return duration;
}

- (NSTimeInterval)currentTime
{
    
    AudioTimeStamp outTimeStamp;
    Boolean outTimelineDiscontinuity;
    /*
     * can fail with -66678
     */
    OSStatus status = AudioQueueGetCurrentTime(mQueue, NULL, &outTimeStamp, &outTimelineDiscontinuity);
    NSTimeInterval currentTime;
    switch(status)
    {
        case noErr:
            currentTime = (NSTimeInterval)outTimeStamp.mSampleTime/self.decoder.dataFormat.mSampleRate + mQueueStartTime;
            break;
        case kAudioQueueErr_InvalidRunState:
            currentTime = 0.0;
            break;
        default:
            currentTime = -1.0;
            
    }
    return mQueueStartTime + currentTime;
}

- (void)setCurrentTime:(NSTimeInterval)currentTime
{
    OggAudioPlayerState previousState = self.state;
    switch(self.state)
    {
        case OggAudioPlayerStatePlaying:
            [self stop:YES];
            break;
        default:
            break;
    }
    [self.decoder seekToTime:currentTime error:nil];
    mQueueStartTime = currentTime;
    switch(previousState)
    {
        case OggAudioPlayerStatePrepared:
            [self prepareToPlay];
            break;
        case OggAudioPlayerStatePlaying:
            [self play];
            break;
        default:
            break;
    }
}

- (NSUInteger)numberOfChannels
{
    return self.decoder.dataFormat.mChannelsPerFrame;
}


- (void)setState:(OggAudioPlayerState)state
{
    switch(state)
    {
        case OggAudioPlayerStatePaused:
            NSLog(@"OggAudioPlayerStatePaused");
            break;
        case OggAudioPlayerStatePlaying:
            NSLog(@"OggAudioPlayerStatePlaying");
            break;
        case OggAudioPlayerStatePrepared:
            NSLog(@"OggAudioPlayerStatePrepared");
            break;
        case OggAudioPlayerStateStopped:
            NSLog(@"OggAudioPlayerStateStopped");
            break;
        case OggAudioPlayerStateStopping:
            NSLog(@"OggAudioPlayerStateStopping");
            break;
    }
    mState = state;
}
@end
