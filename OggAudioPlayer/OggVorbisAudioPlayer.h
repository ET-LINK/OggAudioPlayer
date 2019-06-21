//
//  OggVorbisAudioPlayer.h
//  OggAudioPlayer
//
//  Created by Enter on 2019/6/20.
//  Copyright © 2019 Enter. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OggAudioPlayer.h"
#import "OggAudioDecoder.h"

NS_ASSUME_NONNULL_BEGIN



@interface OggVorbisAudioPlayer : NSObject<OggAudioPlayer>
/**
 * @brief Initialized the receiver to play audio from a specified decoder.
 *
 * @param decoder the decoder to obtain audio data from, must no be nil.
 * @param error will receive error information if not nil.
 * @return a pointer to the receiver or nil if an error occurs.
 */
- (id)initWithDecoder:(id<OggAudioDecoder>)decoder error:(NSError**)error;
/**
 * @brief Delegate notified when playback ends.
 */
@property(assign) id<OggAudioPlayerDelegate> delegate;
/**
 * @brief The current audio device time.
 */
@property(readonly) NSTimeInterval deviceCurrentTime;

@end

NS_ASSUME_NONNULL_END
