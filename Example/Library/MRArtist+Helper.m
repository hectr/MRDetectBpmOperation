// MRArtist+Helper.m
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

#import "MRArtist+Helper.h"

#import "MRLibraryStack.h"
#import "MRManagedObjectContext.h"


@implementation MRArtist (Helper)

+ (MRArtist *)artistInContext:(NSManagedObjectContext *)context
                       withID:(NSNumber *const)artistPersistentID
                         name:(NSString *const)artistName
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
    variables[@"ARTIST_ID"] = artistPersistentID ?: @(0);
    variables[@"ARTIST_NAME"] = artistName ?: @"";
    NSFetchRequest *fetchRequest = [model fetchRequestFromTemplateWithName:@"Artist" substitutionVariables:variables];
    NSArray *const artists = [context executeFetchRequest:fetchRequest error:&fetchError];
    MRArtist *artist = artists.lastObject;
    if (artist == nil && (artistPersistentID.intValue != 0 || artistName.length > 0)) {
        __block NSManagedObjectID *objectID;
        void (^const block)(NSManagedObjectContext *moc) = ^(NSManagedObjectContext *const moc) {
            NSEntityDescription *const entity = [NSEntityDescription entityForName:@"Artist" inManagedObjectContext:moc];
            MRArtist *const artist = [[MRArtist alloc] initWithEntity:entity insertIntoManagedObjectContext:moc];
            artist.name = artistName;
            artist.persistentID = artistPersistentID;
            [moc obtainPermanentIDsForObjects:@[ artist ] error:&obtainError];
            if (context.isReadOnlyContext) {
                if ([moc save:&saveError]) {
                    objectID = artist.objectID;
                } else {
                    ;
                }
            } else {
                objectID = artist.objectID;
            }
        };
        if (context.isReadOnlyContext) {
            [sharedStack performSync:block];
        } else {
            block(context);
        }
        artist = [MRArtist artist:objectID inContext:context withError:&existingError];
    }
    
    if (errorPtr) {
        *errorPtr = fetchError ?: obtainError ?: saveError ?: existingError;
    }
    
    return artist;
}

+ (MRArtist *)artist:(NSManagedObjectID *const)objectID
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
    
    MRArtist *const artist =
    (MRArtist *)[context existingObjectWithID:objectID error:errorPtr];
    return artist;
}

@end
