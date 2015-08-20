// MRSong+Helper.m
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

#import "MRSong+Helper.h"

#import "MRComposer+Helper.h"
#import "MRGenre+Helper.h"
#import "MRAlbum+Helper.h"
#import "MRArtist+Helper.h"
#import "MRArtwork+Helper.h"

#import "MRLibraryStack.h"
#import "MRManagedObjectContext.h"
#import "MRDetectBpmOperation.h"

#import <UIKit/UIKit.h>


@implementation MRSong (Helper)

+ (NSArray *)songsInContext:(NSManagedObjectContext *)context
               withBpmRange:(NSRange const)range
                      error:(NSError **const)errorPtr
{
    MRLibraryStack *const sharedStack = MRLibraryStack.sharedStack;
    if (context == nil) {
        context = sharedStack.readOnlyContext;
    }
    
    NSManagedObjectModel *const model = MRLibraryStack.sharedStack.managedObjectModel;
    NSInteger const lowerLimit = (NSInteger)range.location;
    NSInteger const upperLimit = lowerLimit + range.length;
    NSMutableDictionary *variables = NSMutableDictionary.dictionary;
    variables[@"UPPER_LIMIT"] = @(upperLimit);
    variables[@"LOWER_LIMIT"] = @(lowerLimit);
    NSFetchRequest *fetchRequest = [model fetchRequestFromTemplateWithName:@"SongsWithBpmLimit" substitutionVariables:variables];
    
    NSArray *const songs = [context executeFetchRequest:fetchRequest error:errorPtr];
    return songs;
}

+ (MRSong *)songInContext:(NSManagedObjectContext *)context
                   withID:(NSNumber *const)persistentID
                      uri:(NSString *const)uri
                    title:(NSString *const)title
                  albumID:(NSNumber *const)albumPersistentID
               albumTitle:(NSString *const)albumTitle
                 artistID:(NSNumber *const)artistPersistentID
               artistName:(NSString *const)artistName
                    error:(NSError **const)errorPtr
{
    NSError *fetchError;
    __block NSError *obtainError;
    __block NSError *saveError;
    NSError *existingError;
    
    MRLibraryStack *const sharedStack = MRLibraryStack.sharedStack;
    if (context == nil) {
        context = sharedStack.readOnlyContext;
    }
    NSManagedObjectModel *const model = MRLibraryStack.sharedStack.managedObjectModel;
    NSMutableDictionary *variables = NSMutableDictionary.dictionary;
    variables[@"SONG_URL"] = uri ?: @"";
    variables[@"SONG_ID"] = persistentID ?: @(0);
    variables[@"SONG_TITLE"] = title ?: @"";
    variables[@"ALBUM_ID"] = albumPersistentID ?: @(0);
    variables[@"ALBUM_TITLE"] = albumTitle ?: @"";
    variables[@"ARTIST_ID"] = artistPersistentID ?: @(0);
    variables[@"ARTIST_NAME"] = artistName ?: @"";
    NSFetchRequest *fetchRequest = [model fetchRequestFromTemplateWithName:@"Song" substitutionVariables:variables];
    NSArray *const songs = [context executeFetchRequest:fetchRequest error:&fetchError];
    MRSong *song = songs.lastObject;
    if (song == nil && (uri.length > 0 || persistentID.intValue != 0 || title.length > 0)) {
        __block NSManagedObjectID *objectID;
        void (^const block)(NSManagedObjectContext *moc) = ^(NSManagedObjectContext *const moc) {
            NSEntityDescription *const entity = [NSEntityDescription entityForName:@"Song" inManagedObjectContext:moc];
            MRSong *const song = [[MRSong alloc] initWithEntity:entity insertIntoManagedObjectContext:moc];
            song.assetURLString = uri;
            song.title = title;
            song.persistentID = persistentID;
            [moc obtainPermanentIDsForObjects:@[ song ] error:&obtainError];
            if (context.isReadOnlyContext) {
                if ([moc save:&saveError]) {
                    objectID = song.objectID;
                } else {
                    ;
                }
            } else {
                objectID = song.objectID;
            }
        };
        if (context.isReadOnlyContext) {
            [sharedStack performSync:block];
        } else {
            block(context);
        }
        song = [self song:objectID inContext:context withError:&existingError];
    }
    
    if (errorPtr) {
        *errorPtr = fetchError ?: obtainError ?: saveError ?: existingError;
    }
    
    return song;
}

+ (MRSong *)song:(NSManagedObjectID *const)objectID
       inContext:(NSManagedObjectContext *)context
       withError:(NSError **const)errorPtr
{
    if (context == nil) {
        MRLibraryStack *const sharedStack = MRLibraryStack.sharedStack;
        context = sharedStack.readOnlyContext;
    }
    
    if (objectID == nil) {
        return nil;
    }
    
    MRSong *const song =
    (MRSong *)[context existingObjectWithID:objectID error:errorPtr];
    return song;
}

- (MRArtist *)updateWithArtistPersistentID:(NSNumber *const)artistPersistentID
                                      name:(NSString *const)artistName
                                     error:(NSError **const)errorPtr
{
    NSManagedObjectContext *const moc = self.managedObjectContext;
    MRArtist *const artist = [MRArtist artistInContext:moc withID:artistPersistentID name:artistName error:errorPtr];
    if (artist) {
        self.artist = artist;
        
        if (artistName) {
            artist.name = artistName;
        }
        if (artistPersistentID) {
            artist.persistentID = artistPersistentID;
        }
    }
    return artist;
}

- (MRAlbum *)updateWithAlbumPersistentID:(NSNumber *const)albumPersistentID
                                   title:(NSString *const)albumTitle
                      artistPersistentID:(NSNumber *const)artistPersistentID
                                    name:(NSString *const)artistName
                                   error:(NSError **const)errorPtr
{
    NSManagedObjectContext *const moc = self.managedObjectContext;
    MRAlbum *const album = [MRAlbum albumInContext:moc withID:albumPersistentID title:albumTitle artistID:artistPersistentID artistName:artistName error:errorPtr];
    if (album) {
        self.album = album;
        
        if (albumTitle) {
            album.title = albumTitle;
        }
        if (albumPersistentID) {
            album.persistentID = albumPersistentID;
        }
        
        [album updateWithArtistPersistentID:artistPersistentID name:artistName error:errorPtr];
    }
    return album;
}

- (MRArtwork *)updateWithArtworkImage:(UIImage *const)image error:(NSError **const)errorPtr
{
    NSData *const imageData = UIImageJPEGRepresentation(image, 0.7f);
    
    NSManagedObjectContext *const moc = self.managedObjectContext;
    MRArtwork *const artwork = [MRArtwork artworkInContext:moc withMD5:nil songID:self.persistentID songTitle:self.title error:errorPtr];
    if (artwork) {
        self.artwork = artwork;
        
        if (image) {
            artwork.width = @(image.size.width);
            artwork.height = @(image.size.height);
        }
        
        if (imageData) {
            artwork.imageData = imageData;
        }
        
    }
    return artwork;
}

- (MRComposer *)updateWithComposerPersistentID:(NSNumber *const)composerPersistentID
                                          name:(NSString *const)composerName
                                         error:(NSError **const)errorPtr
{
    NSManagedObjectContext *const moc = self.managedObjectContext;
    MRComposer *const composer = [MRComposer composerInContext:moc withID:composerPersistentID name:composerName error:errorPtr];
    if (composer) {
        self.composer = composer;
        
        if (composerName) {
            composer.name = composerName;
        }
        if (composerPersistentID) {
            composer.persistentID = composerPersistentID;
        }
    }
    return composer;
}

- (MRGenre *)updateWithGenrePersistentID:(NSNumber *const)genrePersistentID
                                    name:(NSString *const)genreName
                                   error:(NSError **const)errorPtr
{
    NSManagedObjectContext *const moc = self.managedObjectContext;
    MRGenre *const genre = [MRGenre genreInContext:moc withID:genrePersistentID name:genreName error:errorPtr];
    if (genre) {
        self.genre = genre;
        
        if (genreName) {
            genre.name = genreName;
        }
        if (genrePersistentID) {
            genre.persistentID = genrePersistentID;
        }
    }
    return genre;
}

- (BOOL)isDetectingBpm
{
    MROperation *const operation = self.bpmOperation;
    return (operation
            && !operation.isFinished
            && !operation.isCancelled);
}

@end
