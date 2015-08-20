// MRDetectBpmOperation.m
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

#import "MRDetectBpmOperation.h"
#import "AVURLAsset+SoundTouch.h"


@interface MRDetectBpmOperation ()
@property (nonatomic, strong, readwrite) NSURL *assetURL;
@property (nonatomic, assign, readwrite) float bpm;
@end


@implementation MRDetectBpmOperation

+ (instancetype)bpmOperationWithAssetURL:(NSURL *const)assetURL
{
    NSParameterAssert(assetURL);
    MRDetectBpmOperation *const operation =
    [(MRDetectBpmOperation *)[self alloc] initWithBlock:^(MRDetectBpmOperation<MRExecutingOperation> *const operation) {
        AVURLAsset *const URLAsset = [AVURLAsset assetWithURL:assetURL];
        if (URLAsset == nil) {
            NSError *const error = [NSError errorWithDomain:NSCocoaErrorDomain
                                                       code:NSFileReadUnknownError
                                                   userInfo:nil];
            [operation finishWithError:error];
        }
        [URLAsset detectBPM:^(float bpm, NSError *error) {
            operation.bpm = bpm;
            [operation finishWithError:error];
        }];
    }];
    
    operation.assetURL = assetURL;
    [operation setShouldExecuteAsBackgroundTaskWithExpirationHandler:nil];
    
    return operation;
}

@end
