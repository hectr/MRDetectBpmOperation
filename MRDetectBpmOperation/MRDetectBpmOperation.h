// MRDetectBpmOperation.h
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

#import "MROperation.h"

/**
 `MRDetectBpmOperation` is a concrete subclass of `NSOperation` that uses the **SoundTouch Audio Processing Library** for detecting BPM of the tracks contained in an `AVURLAsset`.
 */
@interface MRDetectBpmOperation : MROperation

/**
 Creates and returns an `MRDetectBpmOperation` object with the specified media resource URL.
 
 @param assetURL A URL that references a media resource.
 @return A new BPM operation object.
 */
+ (instancetype)bpmOperationWithAssetURL:(NSURL *)assetURL;

/**
 The URL that references the media resource that will be analyzed.
 */
@property (nonatomic, strong, readonly) NSURL *assetURL;

/**
 Upon operation completion, it contains the calculated BPM rate value.
 */
@property (nonatomic, assign, readonly) float bpm;

@end
