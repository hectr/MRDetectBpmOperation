# MRDetectBpmOperation

[![CI Status](http://img.shields.io/travis/hectr/MRDetectBpmOperation.svg?style=flat)](https://travis-ci.org/hectr/MRDetectBpmOperation)
[![Version](https://img.shields.io/cocoapods/v/MRDetectBpmOperation.svg?style=flat)](http://cocoapods.org/pods/MRDetectBpmOperation)
[![License](https://img.shields.io/cocoapods/l/MRDetectBpmOperation.svg?style=flat)](http://cocoapods.org/pods/MRDetectBpmOperation)
[![Platform](https://img.shields.io/cocoapods/p/MRDetectBpmOperation.svg?style=flat)](http://cocoapods.org/pods/MRDetectBpmOperation)

`MRDetectBpmOperation` is a concrete subclass of `NSOperation` that uses the [SoundTouch Audio Processing Library](http://www.surina.net/soundtouch/) for detecting BPM of a media resource.

```
    MRDetectBpmOperation *operation = [MRDetectBpmOperation bpmOperationWithAssetURL:fileURL];
    [operation setCompletionBlockWithSuccess:^(MROperation *operation) {
        NSLog(@"%f", ((MRDetectBpmOperation *)operation).bpm);
    } failure:^(MROperation *operation, NSError *error) {
        NSLog(@"%@", error);
    }];
    [operation start];
```

## Usage

To run the example project, clone the repo, and run `pod install` from the *Example* directory first.

## Installation

### CocoaPods

**MRDetectBpmOperation** is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your *Podfile*:

```ruby
pod "MRDetectBpmOperation"
```

### Manually

Perform the following steps:

- Add the **SoundTouch** library into your project (e.g. copy *External/soundtouch-1.9.0/include* and *External/soundtouch-1.9.0/source/SoundTouch* directories).
- Add `ANDROID=1 SOUNDTOUCH_INTEGER_SAMPLES=1` to `GCC_PREPROCESSOR_DEFINITIONS` in your project settings.
- Copy *MRDetectBpmOperation* directory into your project.

## License

**MRDetectBpmOperation** is available under the MIT license. See the *LICENSE* file for more info.
