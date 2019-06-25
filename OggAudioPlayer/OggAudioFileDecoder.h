//
//  OggAudioFileDecoder.h
//  OggAudioPlayer
//
//  Created by Enter on 2019/6/20.
//  Copyright © 2019 Enter. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "vorbisfile.h"
#import "OggAudioDecoder.h"

NS_ASSUME_NONNULL_BEGIN

@interface OggAudioFileDecoder : NSObject<OggAudioDecoder>
/**
 * @brief Initializes the receiver with the contents of a file URL.
 *
 * @param url a file URL
 * @param error
 * @return a pointer to the receiver or nil if an error occurs
 */
- (id)initWithContentsOfURL:(NSURL*)url error:(NSError**)error;
@end

NS_ASSUME_NONNULL_END
