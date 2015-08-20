// MRArtwork+Helper.m
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

#import "MRArtwork+Helper.h"

#import "MRLibraryStack.h"
#import "MRManagedObjectContext.h"


@implementation MRArtwork (Helper)

+ (MRArtwork *)artworkInContext:(NSManagedObjectContext *)context
                        withMD5:(NSString *const)md5
                         songID:(NSNumber *const)songID
                      songTitle:(NSString *const)songTitle
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
    variables[@"MD5"] = md5 ?: @"";
    variables[@"SONG_ID"] = songID ?: @(0);
    variables[@"SONG_TITLE"] = songTitle ?: @"";
    NSFetchRequest *fetchRequest = [model fetchRequestFromTemplateWithName:@"Artwork" substitutionVariables:variables];
    NSArray *const artworks = [context executeFetchRequest:fetchRequest error:&fetchError];
    MRArtwork *artwork = artworks.lastObject;
    if (artwork == nil && (md5.length > 0 || songID.intValue != 0 || songTitle.length > 0)) {
        __block NSManagedObjectID *objectID;
        void (^const block)(NSManagedObjectContext *moc) = ^(NSManagedObjectContext *const moc) {
            NSEntityDescription *const entity = [NSEntityDescription entityForName:@"Artwork" inManagedObjectContext:moc];
            MRArtwork *const artwork = [[MRArtwork alloc] initWithEntity:entity insertIntoManagedObjectContext:moc];
            artwork.md5 = md5;
            [moc obtainPermanentIDsForObjects:@[ artwork ] error:&obtainError];
            if (context.isReadOnlyContext) {
                if ([moc save:&saveError]) {
                    objectID = artwork.objectID;
                } else {
                    ;
                }
            } else {
                objectID = artwork.objectID;
            }
        };
        if (context.isReadOnlyContext) {
            [sharedStack performSync:block];
        } else {
            block(context);
        }
        artwork = [MRArtwork artwork:objectID inContext:context withError:&existingError];
    }
    
    if (errorPtr) {
        *errorPtr = fetchError ?: obtainError ?: saveError ?: existingError;
    }
    
    return artwork;
}

+ (MRArtwork *)artwork:(NSManagedObjectID *const)objectID
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
    
    MRArtwork *const artwork =
    (MRArtwork *)[context existingObjectWithID:objectID error:errorPtr];
    return artwork;
}

@end
