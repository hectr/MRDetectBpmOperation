// AVURLAsset+SoundTouch.m
//
// Copyright (c) 2014 Héctor Marqués
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "AVURLAsset+SoundTouch.h"

#ifdef __cplusplus
#include "SoundTouch.h"
#include "BPMDetect.h"
#include "TDStretch.h"
#endif


@implementation AVURLAsset (SoundTouch)

- (BOOL)detectBPM:(void(^const)(float bpm, NSError *error))completion
{
    NSParameterAssert(completion);
    
    NSError *error;
    AVAssetReader *const assetReader = [AVAssetReader assetReaderWithAsset:self
                                                                     error:&error];
    if (assetReader == nil){
        completion(0, error);
        return NO;
    }
    
    NSArray *const tracks = [self tracksWithMediaType:AVMediaTypeAudio];
    NSUInteger const trackCount = tracks.count;
    if( trackCount == 0 ) {
        error = [NSError errorWithDomain:NSCocoaErrorDomain
                                    code:NSFileReadCorruptFileError
                                userInfo:nil];
        completion(0, error);
        return NO;
    }
    
    int const numberOfChannels = 2;
    float const sampleRate = 44100.0f;
    int const bitDepth = sizeof(soundtouch::SAMPLETYPE)*8;
    
    NSDictionary *const settings = @{ AVSampleRateKey: @(sampleRate),
                                      AVNumberOfChannelsKey: @(numberOfChannels),
                                      AVLinearPCMBitDepthKey: @(bitDepth),
                                      AVFormatIDKey: @(kAudioFormatLinearPCM),
                                      AVLinearPCMIsFloatKey: @(NO),
                                      AVLinearPCMIsBigEndianKey: @(NO),
                                      AVLinearPCMIsNonInterleaved: @(NO),
                                      AVChannelLayoutKey: NSData.data };
    
    AVAssetReaderAudioMixOutput *const mixOutput =
    [AVAssetReaderAudioMixOutput assetReaderAudioMixOutputWithAudioTracks:tracks
                                                            audioSettings:settings];
    if (![assetReader canAddOutput:mixOutput]) {
        error = [NSError errorWithDomain:AVFoundationErrorDomain
                                    code:AVErrorUnknown
                                userInfo:nil];
        completion(0, error);
        return NO;
    }
    
    [assetReader addOutput:mixOutput];
    
    [assetReader setTimeRange:CMTimeRangeMake(kCMTimeZero, kCMTimePositiveInfinity)];
    if (![assetReader startReading]) {
        completion(0, assetReader.error);
        return NO;
    }
    
    soundtouch::BPMDetect BPM(numberOfChannels, sampleRate);
    
    BOOL success = NO;
    NSMutableData *const data = NSMutableData.data;
    
    while (assetReader.status == AVAssetReaderStatusReading) {
        AVAssetReaderStatus const readerStatus = assetReader.status;
        if (readerStatus == AVAssetReaderStatusFailed ||
            readerStatus == AVAssetReaderStatusCancelled) {
            break;
        } else if (readerStatus == AVAssetReaderStatusReading) {
            CMSampleBufferRef const sampleBuffer = [mixOutput copyNextSampleBuffer];
            if (sampleBuffer) {
                CMBlockBufferRef const blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
                if (blockBuffer) {
                    size_t length;
                    char *dataPointer;
                    OSStatus const result = CMBlockBufferGetDataPointer( blockBuffer
                                                                        , 0
                                                                        , &length
                                                                        , NULL
                                                                        , &dataPointer );
                    if (result == kCMBlockBufferNoErr) {
                        [data appendBytes:dataPointer length:length];
                    }
                }
                CFRelease(sampleBuffer);
            } else {
                success = YES;
                break;
            }
        }
    }
    
    int const numSamples = (int)data.length/sizeof(soundtouch::SAMPLETYPE *)/numberOfChannels;
    BPM.inputSamples((soundtouch::SAMPLETYPE *)data.bytes, numSamples);
    float const bpm = BPM.getBpm();
    completion(bpm, error);
    
    return success;
}

@end
