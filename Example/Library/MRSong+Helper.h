// MRSong+Helper.h
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

#import "MRSong.h"

@class UIImage;


@interface MRSong (Helper)

+ (NSArray *)songsInContext:(NSManagedObjectContext *)context
               withBpmRange:(NSRange const)range
                      error:(NSError **const)errorPtr;

+ (MRSong *)songInContext:(NSManagedObjectContext *)contextOrNil
                   withID:(NSNumber *)persistentID
                      uri:(NSString *)uri
                    title:(NSString *)title
                  albumID:(NSNumber *)albumPersistentID
               albumTitle:(NSString *)albumTitle
                 artistID:(NSNumber *)artistPersistentID
               artistName:(NSString *)artistName
                    error:(NSError **)errorPtr;

+ (MRSong *)song:(NSManagedObjectID *)objectID
       inContext:(NSManagedObjectContext *)contextOrNil
       withError:(NSError **)errorPtr;

- (MRArtist *)updateWithArtistPersistentID:(NSNumber *)artistPersistentID
                                      name:(NSString *)artistName
                                     error:(NSError **)errorPtr;

- (MRAlbum *)updateWithAlbumPersistentID:(NSNumber *)albumPersistentID
                                   title:(NSString *)albumTitle
                      artistPersistentID:(NSNumber *)artistPersistentID
                                    name:(NSString *)artistName
                                   error:(NSError **)errorPtr;

- (MRArtwork *)updateWithArtworkImage:(UIImage *)image
                                error:(NSError **)errorPtr;

- (MRComposer *)updateWithComposerPersistentID:(NSNumber *)composerPersistentID
                                          name:(NSString *)composerName
                                         error:(NSError **)errorPtr;

- (MRGenre *)updateWithGenrePersistentID:(NSNumber *)genrePersistentID
                                    name:(NSString *)genreName
                                   error:(NSError **)errorPtr;

- (BOOL)isDetectingBpm;

@end
