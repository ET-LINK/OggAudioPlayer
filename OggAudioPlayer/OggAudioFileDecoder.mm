//
//  OggAudioFileDecoder.m
//  OggAudioPlayer
//
//  Created by Enter on 2019/6/20.
//  Copyright © 2019 Enter. All rights reserved.
//


#import "OggAudioFileDecoder.h"

#define OGGTrace() NSLog(@"%s", __PRETTY_FUNCTION__)
#define OGG_BITS_PER_BYTE 8
#define OGG_BYTES_TO_BITS(bytes) ((bytes) * OGG_BITS_PER_BYTE)
#define OGG_VORBIS_WORDSIZE 2

@interface OggAudioFileDecoder ()
{
@private
    FILE* mpFile;
    OggVorbis_File mOggVorbisFile;
}

@end

@implementation OggAudioFileDecoder
@synthesize dataFormat = mDataFormat;


- (id)initWithContentsOfURL:(NSURL*)url error:(NSError *__autoreleasing *)error
{
    NSParameterAssert([url isFileURL]);
    if(self = [super init])
    {
        NSString* path = [url path];
        mpFile = fopen([path UTF8String], "r");
        NSAssert(mpFile, @"fopen succeeded.");
        int iReturn = ov_open_callbacks(mpFile, &mOggVorbisFile, NULL, 0, OV_CALLBACKS_NOCLOSE);
        NSAssert(iReturn >= 0, @"ov_open_callbacks succeeded.");
        vorbis_info* pInfo = ov_info(&mOggVorbisFile, -1);
        int bytesPerChannel = OGG_VORBIS_WORDSIZE;
        FillOutASBDForLPCM(mDataFormat,
                           (Float64)pInfo->rate, // sample rate (fps)
                           (UInt32)pInfo->channels, // channels per frame
                           (UInt32)OGG_BYTES_TO_BITS(bytesPerChannel), // valid bits per channel
                           (UInt32)OGG_BYTES_TO_BITS(bytesPerChannel), // total bits per channel
                           false, // isFloat
                           false); // isBigEndian
        
    }
    return self;
}

- (void)dealloc
{
    ov_clear(&mOggVorbisFile);
    if(mpFile)
    {
        fclose(mpFile);
        mpFile = NULL;
    }
}


- (BOOL)readBuffer:(AudioQueueBufferRef)pBuffer
{
    OGGTrace();
    int bigEndian = 0;
    int wordSize = OGG_VORBIS_WORDSIZE;
    int signedSamples = 1;
    int currentSection = -1;
    
    /* See: http://xiph.org/vorbis/doc/vorbisfile/ov_read.html */
    UInt32 nTotalBytesRead = 0;
    long nBytesRead = 0;
    do
    {
        nBytesRead = ov_read(&mOggVorbisFile,
                             (char*)pBuffer->mAudioData + nTotalBytesRead,
                             (int)(pBuffer->mAudioDataBytesCapacity - nTotalBytesRead),
                             bigEndian, wordSize,
                             signedSamples, &currentSection);
        if(nBytesRead  <= 0)
            break;
        nTotalBytesRead += nBytesRead;
    } while(nTotalBytesRead < pBuffer->mAudioDataBytesCapacity);
    if(nTotalBytesRead == 0)
        return NO;
    if(nBytesRead < 0)
    {
        return NO;
    }
    pBuffer->mAudioDataByteSize = nTotalBytesRead;
    pBuffer->mPacketDescriptionCount = 0;
    return YES;
    
}

- (BOOL)seekToTime:(NSTimeInterval)time error:(NSError**)error
{
    /*
     * Possible errors are OV_ENOSEEK, OV_EINVAL, OV_EREAD, OV_EFAULT, OV_EBADLINK
     * See: http://xiph.org/vorbis/doc/vorbisfile/ov_time_seek.html
     */
    int iResult = ov_time_seek(&mOggVorbisFile, time);
    NSLog(@"ov_time_seek(%g) = %d", time, iResult);
    return (iResult == 0);
}

// MARK: - Dynamic Properties
- (NSTimeInterval)duration
{
    double duration = ov_time_total(&mOggVorbisFile, -1);
    return (NSTimeInterval)duration;
}


@end
