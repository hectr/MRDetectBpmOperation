// MRAlbum+Helper.m
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

#import "MRAlbum+Helper.h"

#import "MRLibraryStack.h"
#import "MRManagedObjectContext.h"
#import "MRArtist+Helper.h"


@implementation MRAlbum (Helper)

+ (MRAlbum *)albumInContext:(NSManagedObjectContext *)context
                     withID:(NSNumber *const)albumPersistentID
                      title:(NSString *const)albumTitle
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
    variables[@"ALBUM_ID"] = albumPersistentID ?: @(0);
    variables[@"ALBUM_TITLE"] = albumTitle ?: @"";
    variables[@"ARTIST_ID"] = artistPersistentID ?: @(0);
    variables[@"ARTIST_NAME"] = artistName ?: @"";
    NSFetchRequest *fetchRequest = [model fetchRequestFromTemplateWithName:@"Album" substitutionVariables:variables];
    NSArray *const albums = [context executeFetchRequest:fetchRequest error:&fetchError];
    MRAlbum *album = albums.lastObject;
    if (album == nil && (albumPersistentID.intValue != 0 || albumTitle.length > 0)) {
        __block NSManagedObjectID *objectID;
        void (^const block)(NSManagedObjectContext *moc) = ^(NSManagedObjectContext *const moc) {
            NSEntityDescription *const entity = [NSEntityDescription entityForName:@"Album" inManagedObjectContext:moc];
            MRAlbum *const album = [[MRAlbum alloc] initWithEntity:entity insertIntoManagedObjectContext:moc];
            album.title = albumTitle;
            album.persistentID = albumPersistentID;
            [moc obtainPermanentIDsForObjects:@[ album ] error:&obtainError];
            if (context.isReadOnlyContext) {
                if ([moc save:&saveError]) {
                    objectID = album.objectID;
                } else {
                    ;
                }
            } else {
                objectID = album.objectID;
            }
        };
        if (context.isReadOnlyContext) {
            [sharedStack performSync:block];
        } else {
            block(context);
        }
        album = [MRAlbum album:objectID inContext:context withError:&existingError];
    }
    
    if (errorPtr) {
        *errorPtr = fetchError ?: obtainError ?: saveError ?: existingError;
    }
    
    return album;
}

+ (MRAlbum *)album:(NSManagedObjectID *const)objectID
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
    
    MRAlbum *const album =
    (MRAlbum *)[context existingObjectWithID:objectID error:errorPtr];
    return album;
}

- (MRArtist *)updateWithArtistPersistentID:(NSNumber *const)artistPersistentID name:(NSString *const)artistName error:(NSError **const)errorPtr
{
    NSManagedObjectContext *const moc = self.managedObjectContext;
    MRArtist *artist = [MRArtist artistInContext:moc withID:artistPersistentID name:artistName error:errorPtr];
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

@end
