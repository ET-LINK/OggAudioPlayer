//
//  OggAudioDecoder.h
//  OggAudioPlayer
//
//  Created by Enter on 2019/6/20.
//  Copyright © 2019 Enter. All rights reserved.
//

#ifndef OggAudioDecoder_h
#define OggAudioDecoder_h
#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@protocol OggAudioDecoder <NSObject>
@required
/**
 * @brief Description of the audio format produced by this decoder.
 *
 * This must be one of the audio format supported by iOS.
 */
@property(readonly) AudioStreamBasicDescription dataFormat;
/**
 * @brief The duration of the source in seconds.
 */
@property(readonly) NSTimeInterval duration;
/**
 * @brief Fills an audio buffer with decoded audio data from the source.
 */
- (BOOL)readBuffer:(AudioQueueBufferRef)buffer;
/**
 * @brief Seeks to a specified time in an audio source.
 *
 * @param timeInterval the time in seconds from the start of the source.
 * @param error if not nil will receive error information in case of an error.
 * @return YES if successful, NO if an error occurs.
 */
- (BOOL)seekToTime:(NSTimeInterval)timeInterval error:(NSError*__autoreleasing*)error;

@end

#endif /* OggAudioDecoder_h */
