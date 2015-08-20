// MRGenre+Helper.m
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

#import "MRGenre+Helper.h"

#import "MRLibraryStack.h"
#import "MRManagedObjectContext.h"


@implementation MRGenre (Helper)

+ (MRGenre *)genreInContext:(NSManagedObjectContext *)context
                     withID:(NSNumber *const)genrePersistentID
                       name:(NSString *const)genreName
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
    variables[@"GENRE_ID"] = genrePersistentID ?: @(0);
    variables[@"GENRE_NAME"] = genreName ?: @"";
    NSFetchRequest *fetchRequest = [model fetchRequestFromTemplateWithName:@"Genre" substitutionVariables:variables];
    NSArray *const genres = [context executeFetchRequest:fetchRequest error:&fetchError];
    MRGenre *genre = genres.lastObject;
    if (genre == nil && (genrePersistentID.intValue != 0 || genreName.length > 0)) {
        __block NSManagedObjectID *objectID;
        void (^const block)(NSManagedObjectContext *moc) = ^(NSManagedObjectContext *const moc) {
            NSEntityDescription *const entity = [NSEntityDescription entityForName:@"Genre" inManagedObjectContext:moc];
            MRGenre *const genre = [[MRGenre alloc] initWithEntity:entity insertIntoManagedObjectContext:moc];
            genre.name = genreName;
            genre.persistentID = genrePersistentID;
            [moc obtainPermanentIDsForObjects:@[ genre ] error:&obtainError];
            if (context.isReadOnlyContext) {
                if ([moc save:&saveError]) {
                    objectID = genre.objectID;
                } else {
                    ;
                }
            } else {
                objectID = genre.objectID;
            }
        };
        if (context.isReadOnlyContext) {
            [sharedStack performSync:block];
        } else {
            block(context);
        }
        genre = [MRGenre genre:objectID inContext:context withError:&existingError];
    }
    
    if (errorPtr) {
        *errorPtr = fetchError ?: obtainError ?: saveError ?: existingError;
    }
    
    return genre;
}

+ (MRGenre *)genre:(NSManagedObjectID *const)objectID
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
    
    MRGenre *const genre =
    (MRGenre *)[context existingObjectWithID:objectID error:errorPtr];
    return genre;
}

@end
