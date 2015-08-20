// MRDetectBpmOperationTests.m
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

#import <XCTest/XCTest.h>
#import "MRDetectBpmOperation.h"


@interface Tests : XCTestCase
@end


@implementation Tests

- (void)testThatOperationIsCreated
{
    NSURL *const URL = [NSURL URLWithString:@"/"];
    MRDetectBpmOperation *o = [MRDetectBpmOperation bpmOperationWithAssetURL:URL];
    XCTAssertNotNil(o);
}

- (void)testThatOperationFailsIfURLIsNil
{
    __block BOOL success = NO;
    @try {
        MRDetectBpmOperation *o = [MRDetectBpmOperation bpmOperationWithAssetURL:nil];
        __weak typeof(o) weakOp = o;
        o.completionBlock = ^{
            XCTAssertNotNil(weakOp.error);
            success = YES;
        };
        [o start];
        [NSRunLoop.mainRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
        XCTAssertTrue(success);
    }
    @catch (NSException *exception) {
        ; // NSParameterAssert
    }
}

- (void)testThatOperationFails
{
    __block BOOL success = NO;
    NSURL *const URL = [[NSBundle bundleForClass:self.class] URLForResource:@"invalid"
                                                              withExtension:@"mp3"];
    MRDetectBpmOperation *o = [MRDetectBpmOperation bpmOperationWithAssetURL:URL];
    __weak typeof(o) weakOp = o;
    o.completionBlock = ^{
        XCTAssertNotNil(weakOp.error);
        success = YES;
    };
    [o start];
    [NSRunLoop.mainRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
    XCTAssertTrue(success);
}

- (void)testThatFailureBlockIsInvoked
{
    __block BOOL success = NO;
    NSURL *const URL = [[NSBundle bundleForClass:self.class] URLForResource:@"invalid"
                                                              withExtension:@"mp3"];
    MRDetectBpmOperation *o = [MRDetectBpmOperation bpmOperationWithAssetURL:URL];
    [o setCompletionBlockWithSuccess:^(MROperation *operation) {
        XCTFail();
    } failure:^(MROperation *operation, NSError *error) {
        XCTAssertEqualObjects(operation.class, MRDetectBpmOperation.class);
        success = YES;
    }];
    [o start];
    [NSRunLoop.mainRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
    XCTAssertTrue(success);
}

- (void)testThatOperationSucceeds
{
    __block BOOL success = NO;
    NSURL *const URL = [[NSBundle bundleForClass:self.class] URLForResource:@"most_annoying_sound_ever-Ethan_Buck-1557665457"
                                                              withExtension:@"mp3"];
    MRDetectBpmOperation *o = [MRDetectBpmOperation bpmOperationWithAssetURL:URL];
    __weak typeof(o) weakOp = o;
    o.completionBlock = ^{
        XCTAssertNil(weakOp.error);
        XCTAssertNotEqual(weakOp.bpm, 0.0f);
        success = YES;
    };
    [o start];
    [NSRunLoop.mainRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    XCTAssertTrue(success);
}

- (void)testThatSuccessBlockIsInvoked
{
    __block BOOL success = NO;
    NSURL *const URL = [[NSBundle bundleForClass:self.class] URLForResource:@"most_annoying_sound_ever-Ethan_Buck-1557665457"
                                                              withExtension:@"mp3"];
    MRDetectBpmOperation *o = [MRDetectBpmOperation bpmOperationWithAssetURL:URL];
    [o setCompletionBlockWithSuccess:^(MROperation *operation) {
        XCTAssertEqualObjects(operation.class, MRDetectBpmOperation.class);
        XCTAssertNotEqual(((MRDetectBpmOperation *)operation).bpm, 0.0f);
        success = YES;
    } failure:^(MROperation *operation, NSError *error) {
        XCTFail();
    }];
    [o start];
    [NSRunLoop.mainRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    XCTAssertTrue(success);
}

@end

