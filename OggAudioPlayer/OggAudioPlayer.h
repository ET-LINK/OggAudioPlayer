//
//  OggAudioPlayer.h
//  OggAudioPlayer
//
//  Created by Enter on 2019/6/20.
//  Copyright © 2019 Enter. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

//! Project version number for OggAudioPlayer.
FOUNDATION_EXPORT double OggAudioPlayerVersionNumber;

//! Project version string for OggAudioPlayer.
FOUNDATION_EXPORT const unsigned char OggAudioPlayerVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <OggAudioPlayer/PublicHeader.h>

@protocol OggAudioPlayer;
/**
 * @brief Receives notifications when playback ends.
 */
@protocol OggAudioPlayerDelegate
/**
 * @brief Called when playback ends.
 */
- (void)audioPlayerDidFinishPlaying:(id<OggAudioPlayer>)player
                       successfully:(BOOL)flag;
/**
 * @brief Called when a decode error occurs.
 */
- (void)audioPlayerDecodeErrorDidOccur:(id<OggAudioPlayer>)player
                                 error:(NSError *)error;
@end


@protocol OggAudioPlayer <NSObject>

/**
 * @brief Pre-queues buffers for faster response to #play
 */
- (BOOL)prepareToPlay;
/**
 * @brief Begins playback.
 */
- (BOOL)play;
/**
 * @brief Pauses playback.
 */
- (BOOL)pause;
/**
 * @brief Stops playback.
 */
- (BOOL)stop;

/* properties */
/**
 * @brief YES when the player is playing, NO otherwise.
 */
@property(readonly, getter=isPlaying) BOOL playing;
/**
 * @brief Number of channels in the audio source.
 */
@property(readonly) NSUInteger numberOfChannels;
/**
 * @brief Duration of the source in seconds.
 */
@property(readonly) NSTimeInterval duration;
/**
 * @brief Delegate for notifications.
 */
@property(assign) id<OggAudioPlayerDelegate> delegate;
/**
 * @brief Current playback time in seconds.
 */
@property NSTimeInterval currentTime;
/**
 * @brief Current audio device time in seconds.
 */
@property(readonly) NSTimeInterval deviceCurrentTime;

@end
