// MRComposer+Helper.m
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

#import "MRComposer+Helper.h"

#import "MRLibraryStack.h"
#import "MRManagedObjectContext.h"


@implementation MRComposer (Helper)

+ (MRComposer *)composerInContext:(NSManagedObjectContext *)context
                           withID:(NSNumber *const)composerPersistentID
                             name:(NSString *const)composerName
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
    variables[@"COMPOSER_ID"] = composerPersistentID ?: @(0);
    variables[@"COMPOSER_NAME"] = composerName ?: @"";
    NSFetchRequest *fetchRequest = [model fetchRequestFromTemplateWithName:@"Composer" substitutionVariables:variables];
    NSArray *const composers = [context executeFetchRequest:fetchRequest error:&fetchError];
    MRComposer *composer = composers.lastObject;
    if (composer == nil && (composerPersistentID.intValue != 0 || composerName.length > 0)) {
        __block NSManagedObjectID *objectID;
        void (^const block)(NSManagedObjectContext *moc) = ^(NSManagedObjectContext *const moc) {
            NSEntityDescription *const entity = [NSEntityDescription entityForName:@"Composer" inManagedObjectContext:moc];
            MRComposer *const composer = [[MRComposer alloc] initWithEntity:entity insertIntoManagedObjectContext:moc];
            composer.name = composerName;
            composer.persistentID = composerPersistentID;
            [moc obtainPermanentIDsForObjects:@[ composer ] error:&obtainError];
            if (context.isReadOnlyContext) {
                if ([moc save:&saveError]) {
                    objectID = composer.objectID;
                } else {
                    ;
                }
            } else {
                objectID = composer.objectID;
            }
        };
        if (context.isReadOnlyContext) {
            [sharedStack performSync:block];
        } else {
            block(context);
        }
        composer = [MRComposer composer:objectID inContext:context withError:&existingError];
    }
    
    if (errorPtr) {
        *errorPtr = fetchError ?: obtainError ?: saveError ?: existingError;
    }
    
    return composer;
}

+ (MRComposer *)composer:(NSManagedObjectID *const)objectID
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
    
    MRComposer *const composer =
    (MRComposer *)[context existingObjectWithID:objectID error:errorPtr];
    return composer;
}

@end
