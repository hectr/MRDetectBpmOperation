// MRMusicVC.m
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


#import "MRMusicVC.h"

#import <Storekit/StoreKit.h>
#import <ErrorKit/ErrorKit.h>

#import "MRSong+Helper.h"
#import "MRAlbum+Helper.h"
#import "MRArtist+Helper.h"
#import "MRArtwork+Helper.h"

#import "MRDetectBpmOperation.h"
#import "MRLibraryStack.h"
#import "MRSong.h"
#import "MRArtwork.h"
#import "MRAlbum.h"
#import "MRArtist.h"
#import "MRComposer.h"
#import "MRGenre.h"
#import "MRTableViewSubtitleCell.h"

#import <MediaPlayer/MediaPlayer.h>


@interface MRMusicVC () <MPMediaPickerControllerDelegate, NSFetchedResultsControllerDelegate> {
    id<NSObject> _foregroundNotificationTicket;
    id<NSObject> _backgroundNotificationTicket;
}
@property (strong, nonatomic) IBOutlet NSFetchedResultsController *resultsController;
@property (strong, nonatomic) IBOutlet NSFetchedResultsController *searchResultsController;
@property (strong, nonatomic) NSOperationQueue *bpmQueue;
@end


@implementation MRMusicVC

#pragma mark Library handling

- (void)pickMusicFromLibrary
{
    MPMediaPickerController *const mediaPicker =
    [[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeMusic];
    mediaPicker.delegate = self;
    mediaPicker.allowsPickingMultipleItems = YES;
    
    [self presentViewController:mediaPicker animated:YES completion:nil];
}

- (void)gatherMediaItemsData:(MPMediaItemCollection *const)mediaItemCollection
{
    NSArray *const operations = _bpmQueue.operations;
    NSArray *const assetURLs = [operations valueForKey:@"assetURL"];
    
    NSArray *const items = mediaItemCollection.items;
    NSMutableArray *const errors = NSMutableArray.array;
    NSMutableArray *const objectIDs = NSMutableArray.array;
    for (MPMediaItem *const item in items) {
        NSError *error;
        NSManagedObjectID *const objectID =
        [self songObjectIDForMediaItem:item alreadyEnqueuedAssetURLs:assetURLs error:&error];
        if (objectID) {
            [objectIDs addObject:objectID];
        } else if (error) {
            [errors addObject:error];
        }
    }
    NSAssert(errors.count == 0, @"%ld unhandled errors occurred", (long)errors.count);
}

- (void)dismissPresentedViewControllerAnimated
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSManagedObjectID *)songObjectIDForMediaItem:(MPMediaItem *const)item
                       alreadyEnqueuedAssetURLs:(NSArray *const)assetURLs
                                          error:(NSError **const)errorPtr
{
    __block MRSong *song;
    
    NSNumber *const isCloudItem = [item valueForProperty:MPMediaItemPropertyIsCloudItem];
    if (isCloudItem.boolValue == NO) {
        
        NSURL *const URL = [item valueForProperty:MPMediaItemPropertyAssetURL];
        NSString *const uri = URL.absoluteString;
        NSNumber *const persistentID = [item valueForProperty:MPMediaItemPropertyPersistentID];
        NSString *const title = [item valueForProperty:MPMediaItemPropertyTitle];
        NSString *const albumTitle = [item valueForProperty:MPMediaItemPropertyAlbumTitle];
        NSNumber *const albumPersistentID = [item valueForProperty:MPMediaItemPropertyAlbumPersistentID];
        NSString *const artistName = [item valueForProperty:MPMediaItemPropertyArtist];
        NSNumber *const artistPersistentID = [item valueForProperty:MPMediaItemPropertyArtistPersistentID];
        
        MRLibraryStack *const sharedStack = MRLibraryStack.sharedStack;
        [sharedStack performSync:^(NSManagedObjectContext *const moc) {
            song = [MRSong songInContext:moc withID:persistentID uri:uri title:title albumID:albumPersistentID albumTitle:albumTitle artistID:artistPersistentID artistName:artistName error:errorPtr];
            if (song) {
                
                if (uri) {
                    song.assetURLString = uri;
                }
                if (title) {
                    song.title = title;
                }
                if (persistentID) {
                    song.persistentID = persistentID;
                }
                
                NSNumber *const bpm = [item valueForProperty:MPMediaItemPropertyBeatsPerMinute];
                if (bpm) {
                    song.bpm = bpm;
                }
                
                NSDate *const lastPlayDate = [item valueForProperty:MPMediaItemPropertyLastPlayedDate];
                if (lastPlayDate) {
                    song.lastPlayTime = @([lastPlayDate timeIntervalSince1970]);
                }
                                
                NSNumber *const rating = [item valueForProperty:MPMediaItemPropertyRating];
                if (rating) {
                    song.rating = rating;
                }
                
                NSString *const lyrics = [item valueForProperty:MPMediaItemPropertyLyrics];
                if (lyrics) {
                    song.lyrics = lyrics;
                }
                
                NSNumber *const duration = [item valueForProperty:MPMediaItemPropertyPlaybackDuration];
                if (duration) {
                    song.duration = duration;
                }

                MPMediaItemArtwork *const itemArtwork = [item valueForProperty:MPMediaItemPropertyArtwork];
                UIImage *const image = [itemArtwork imageWithSize:CGSizeMake(100, 100)];
                [song updateWithArtworkImage:image error:errorPtr];
                
                [song updateWithArtistPersistentID:artistPersistentID name:artistName error:errorPtr];

                
                NSString *const albumArtistName = [item valueForProperty:MPMediaItemPropertyAlbumArtist];
                NSNumber *const albumArtistPersistentID = [item valueForProperty:MPMediaItemPropertyAlbumArtistPersistentID];
                [song updateWithAlbumPersistentID:albumPersistentID title:albumTitle artistPersistentID:albumArtistPersistentID name:albumArtistName error:errorPtr];

                NSString *const genreName = [item valueForProperty:MPMediaItemPropertyGenre];
                NSNumber *const genrePersistentID = [item valueForProperty:MPMediaItemPropertyGenrePersistentID];
                [song updateWithGenrePersistentID:genrePersistentID name:genreName error:errorPtr];

                NSString *const composerName = [item valueForProperty:MPMediaItemPropertyComposer];
                NSNumber *const composerPersistentID = [item valueForProperty:MPMediaItemPropertyComposerPersistentID];
                [song updateWithComposerPersistentID:composerPersistentID name:composerName error:errorPtr];
                
                if (moc.hasChanges) {
                    NSError *saveError;
                    [moc save:&saveError];
                    MRNotErrorAssert(saveError);
                }
                
                if (URL && song.bpm.intValue == 0 && !song.isDetectingBpm) {
                    if (![assetURLs containsObject:URL]) {
                        [self enqueueOperationWithAssetURL:URL andSongID:song.objectID];
                    }
                }
            }
        }];
    }
    
    NSManagedObjectID *const objectID = song.objectID;
    return objectID;
}

#pragma mark Tables handling

- (NSFetchedResultsController *)resultsControllerForTableView:(UITableView *const)tableView
{
    NSFetchedResultsController *resultsController;
    if (_tableView == tableView) {
        resultsController = _resultsController;
    } else if (self.searchDisplayController.searchResultsTableView == tableView) {
        resultsController = _searchResultsController;
    }
    return resultsController;
}

- (UITableView *)tableViewForResultsController:(NSFetchedResultsController *const)resultsController
{
    UITableView *tableView;
    if (resultsController == _resultsController) {
        tableView = _tableView;
    } else if (resultsController == _searchResultsController) {
        tableView = self.searchDisplayController.searchResultsTableView;
    }
    return tableView;
}

- (void)configureCell:(UITableViewCell *const)cell
           withObject:(MRSong *const)object
{
    MRAlbum *const album = object.album;
    NSString *const albumTitle = album.title;
    NSString *const artistName = object.artist.name ?: album.artist.name;
    NSNumber *const BPM = object.bpm;
    NSInteger bpm = BPM.integerValue;
    NSMutableArray *const components = NSMutableArray.array;
    
    if (bpm > 0 && bpm < 200) {
        [components addObject:[NSString stringWithFormat:@"%ld bpm", (long)bpm]];
    } else {
        [components addObject:@"?? bpm"];
    }
    if (artistName.length > 0) {
        [components addObject:artistName];
    }
    if (albumTitle.length > 0) {
        [components addObject:albumTitle];
    }
    NSString *const title = object.title ?: @"--";
    cell.textLabel.text = title;
    cell.detailTextLabel.text = [components componentsJoinedByString:@" - "];
    
    NSData *const imageData = object.artwork.imageData;
    UIImage *image;
    if (imageData) {
        image = [UIImage imageWithData:imageData];
    }
    cell.imageView.image = image;
    
    if (object.isDetectingBpm) {
        UIActivityIndicatorView *const spinner =
        [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        cell.accessoryView = spinner;
        [spinner startAnimating];
    } else {
        cell.accessoryView = nil;
    }
}

#pragma mark Queue handling

- (MRDetectBpmOperation *)enqueueOperationWithAssetURL:(NSURL *const)assetURL
                                             andSongID:(NSManagedObjectID *const)songID
{
    MRLibraryStack *sharedStack = MRLibraryStack.sharedStack;
    
    __weak __typeof(self) const weakSelf = self;
    MRDetectBpmOperation *const operation =
    [MRDetectBpmOperation bpmOperationWithAssetURL:assetURL];
    [operation setCompletionBlockWithSuccess:^(MROperation *operation) {
        MRDetectBpmOperation *const bpmOperation = (MRDetectBpmOperation *)operation;
        [sharedStack performSync:^(NSManagedObjectContext *moc) {
            NSError *existingError;
            MRSong *const song = [MRSong song:songID inContext:moc withError:&existingError];
            MRNotErrorAssert(existingError);
            song.bpm = @(bpmOperation.bpm);
            song.bpmOperation = nil;
            if (moc.hasChanges) {
                NSError *saveError;
                [moc save:&saveError];
                MRNotErrorAssert(saveError);
            }
            NSError *saveError;
            [sharedStack persistChanges:&saveError];
            MRNotErrorAssert(saveError);
            [weakSelf updateTabBarItemBadgeAsync];
        }];
    } failure:^(MROperation *operation, NSError *error) {
        [sharedStack performSync:^(NSManagedObjectContext *moc) {
            NSError *existingError;
            MRSong *const song = [MRSong song:songID inContext:moc withError:&existingError];
            MRNotErrorAssert(existingError);
            song.bpmOperation = nil;
            if (moc.hasChanges) {
                NSError *saveError;
                [moc save:&saveError];
                MRNotErrorAssert(saveError);
            }
            NSError *saveError;
            [sharedStack persistChanges:&saveError];
            MRNotErrorAssert(saveError);
            [weakSelf updateTabBarItemBadgeAsync];
        }];
    }];
    
    [sharedStack performSync:^(NSManagedObjectContext *moc) {
        NSError *existingError;
        MRSong *const song = [MRSong song:songID inContext:moc withError:&existingError];
        MRNotErrorAssert(existingError);
        song.bpmOperation = operation;
        if (moc.hasChanges) {
            NSError *saveError;
            [moc save:&saveError];
            MRNotErrorAssert(saveError);
            [sharedStack persistChanges:&saveError];
            MRNotErrorAssert(saveError);
        }
    }];
    [_bpmQueue addOperation:operation];
    [self updateTabBarItemBadgeAsync];
    return operation;
}

- (void)enqueuePendingBpmOperations
{
    NSString *message;
    NSUInteger const operationCount = _bpmQueue.operationCount;
    if (operationCount > 0) {
        message = [NSString stringWithFormat:NSLocalizedString(@"%@ songs are already being detected.", nil), @(operationCount)];
    } else {
        
        NSRange const range = NSMakeRange(0, 0);
        NSError *fetchError;
        NSArray *const nonDetectedSongs = [MRSong songsInContext:nil withBpmRange:range error:&fetchError];
        MRNotErrorAssert(fetchError);
        for (MRSong *const song in nonDetectedSongs) {
            NSString *const uri = song.assetURLString;
            NSURL *const URL = [NSURL URLWithString:uri];
            NSManagedObjectID *const objectID = song.objectID;
            if (URL && song.bpm.intValue == 0 && !song.isDetectingBpm) {
                [self enqueueOperationWithAssetURL:URL andSongID:objectID];
            }
        }
        
        NSUInteger const songCount = nonDetectedSongs.count;
        if (songCount > 0) {
            message = [NSString stringWithFormat:NSLocalizedString(@"Detecting %@ bpm.", nil), @(songCount)];
        } else if (_tableView.numberOfSections > 0
                   && [_tableView numberOfRowsInSection:0] > 0) {
            message = NSLocalizedString(@"All songs have already been detected.", nil);
        } else {
            message = NSLocalizedString(@"You should add songs from your library first.", nil);
        }
    }
    
    UIAlertView *const alert =
    [[UIAlertView alloc] initWithTitle:nil
                               message:message
                              delegate:nil
                     cancelButtonTitle:NSLocalizedString(@"OK", nil)
                     otherButtonTitles:nil];
    [alert show];
}

#pragma mark Set up

- (void)setUpTableContentInset
{
    UIEdgeInsets contentInset = _tableView.contentInset;
    contentInset.bottom = 10.0f;
    _tableView.contentInset = contentInset;
}

- (void)setUpTableViewContentOffsetAsync
{
    static const CGFloat STATUS_BAR_HEIGHT = 20.0f;
    
    UISearchBar *const searchBar = self.searchDisplayController.searchBar;
    CGFloat const searchBarHeight = searchBar.frame.size.height;
    
    UIEdgeInsets contentInset = _tableView.contentInset;
    contentInset.top -= searchBarHeight;
    _tableView.contentInset = contentInset;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIEdgeInsets contentInset = _tableView.contentInset;
        contentInset.top += searchBarHeight;
        _tableView.contentInset = contentInset;
        
        CGPoint contentOffset = CGPointMake(0.0f, -STATUS_BAR_HEIGHT);
        [_tableView setContentOffset:contentOffset animated:NO];
    });
}

- (void)registerTableViewCells
{
    NSString *const reuseIdentifier = NSStringFromClass(MRTableViewSubtitleCell.class);
    [_tableView registerClass:MRTableViewSubtitleCell.class
       forCellReuseIdentifier:reuseIdentifier];
    UITableView *const searchResultsTableView =
    self.searchDisplayController.searchResultsTableView;
    [searchResultsTableView registerClass:MRTableViewSubtitleCell.class
                   forCellReuseIdentifier:reuseIdentifier];
}

- (void)registerApplicationNotifications
{
    NSNotificationCenter *const defaultCenter = NSNotificationCenter.defaultCenter;
    
    __weak __typeof(self) const weakSelf = self;
    _foregroundNotificationTicket =
    [defaultCenter addObserverForName:UIApplicationWillEnterForegroundNotification
                               object:nil
                                queue:nil
                           usingBlock:
     ^(NSNotification *const note) {
         _bpmQueue.suspended = NO;
         [weakSelf configureVisibleCells];
     }];
    _backgroundNotificationTicket =
    [defaultCenter addObserverForName:UIApplicationDidEnterBackgroundNotification
                               object:nil
                                queue:nil
                           usingBlock:
     ^(NSNotification *const note) {
         _bpmQueue.suspended = YES;
         [weakSelf dismissPresentedViewControllerAnimated];
    }];
}

- (void)unregisterApplicationNotifications
{
    NSNotificationCenter *const defaultCenter = NSNotificationCenter.defaultCenter;
    if (_foregroundNotificationTicket) {
        [defaultCenter removeObserver:_foregroundNotificationTicket];
    }
    if (_backgroundNotificationTicket) {
        [defaultCenter removeObserver:_backgroundNotificationTicket];
    }
}

- (void)setUpResultsController
{
    NSString *const cacheName = [NSString stringWithFormat:@"%p", self];
    if (_resultsController == nil) {
        MRLibraryStack *const sharedStack = MRLibraryStack.sharedStack;
        NSManagedObjectContext *const moc = sharedStack.readOnlyContext;
        NSFetchRequest *const fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Song"];
        NSSortDescriptor *const sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES];
        fetchRequest.sortDescriptors = @[ sortDescriptor ];
        _resultsController =
        [[NSFetchedResultsController alloc]initWithFetchRequest:fetchRequest
                                           managedObjectContext:moc
                                             sectionNameKeyPath:nil
                                                      cacheName:cacheName];
        _resultsController.delegate = self;
    } else {
        [NSFetchedResultsController deleteCacheWithName:cacheName];
    }
    
    NSError *fetchError;
    [_resultsController performFetch:&fetchError];
    MRNotErrorAssert(fetchError);
}

- (void)setUpSearchResultsController
{
    MRLibraryStack *const sharedStack = MRLibraryStack.sharedStack;
    NSManagedObjectContext *const moc = sharedStack.readOnlyContext;
    NSManagedObjectModel *const model = MRLibraryStack.sharedStack.managedObjectModel;
    NSMutableDictionary *variables = NSMutableDictionary.dictionary;
    NSString *const searchTerm = self.searchDisplayController.searchBar.text;
    variables[@"SEARCH_TERM"] = searchTerm ?: @"";
    NSFetchRequest *fetchRequest = [model fetchRequestFromTemplateWithName:@"SongsWithSearchTerm" substitutionVariables:variables];
    NSSortDescriptor *const sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES];
    fetchRequest.sortDescriptors = @[ sortDescriptor ];
    _searchResultsController =
    [[NSFetchedResultsController alloc]initWithFetchRequest:fetchRequest
                                       managedObjectContext:moc
                                         sectionNameKeyPath:nil
                                                  cacheName:nil];
    _searchResultsController.delegate = self;
    
    NSError *fetchError;
    [_searchResultsController performFetch:&fetchError];
    MRNotErrorAssert(fetchError);
}

- (void)setUpBpmOperationQueue
{
    self.bpmQueue = [[NSOperationQueue alloc] init];
    _bpmQueue.maxConcurrentOperationCount = 1;
}

- (void)updateTabBarItemBadgeAsync
{
    UITabBarItem *tabBarItem = (UITabBarItem *)self.navigationController.tabBarItem;
    dispatch_async(dispatch_get_main_queue(), ^{
        NSInteger operationCount = _bpmQueue.operationCount;
        if (operationCount == 0) {
            tabBarItem.badgeValue = nil;
        } else {
            tabBarItem.badgeValue =
            [NSString stringWithFormat:@"%ld", (long)operationCount];
        }
    });
}

- (void)configureVisibleCells
{
    NSArray *const visibleCells = _tableView.visibleCells.copy;
    for (UITableViewCell *const cell in visibleCells) {
        NSIndexPath *const indexPath = [_tableView indexPathForCell:cell];
        MRSong *const song = [_resultsController objectAtIndexPath:indexPath];
        [self configureCell:cell withObject:song];
    }
}

#pragma mark - IB Actions

- (IBAction)addMusicAction:(UIBarButtonItem *const)sender
{
    [self pickMusicFromLibrary];
}

- (IBAction)detectMissingBpmAction:(UIBarButtonItem *const)sender
{
    [self enqueuePendingBpmOperations];
}

#pragma mark - MPMediaPickerControllerDelegate

- (void)mediaPickerDidCancel:(MPMediaPickerController *const)mediaPicker
{
    [self dismissPresentedViewControllerAnimated];
}

- (void)mediaPicker:(MPMediaPickerController *const)mediaPicker
  didPickMediaItems:(MPMediaItemCollection *const)mediaItemCollection
{
    [self dismissPresentedViewControllerAnimated];
    [self gatherMediaItemsData:mediaItemCollection];
}

#pragma mark - UISearchDisplayDelegate

 - (BOOL)searchDisplayController:(UISearchDisplayController *const)controller
shouldReloadTableForSearchString:(NSString *const)searchString
{
    [self setUpSearchResultsController];
    return YES;
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *const)tableView
 numberOfRowsInSection:(NSInteger const)section
{
    NSFetchedResultsController *const resultsController = [self resultsControllerForTableView:tableView];
    NSArray *const sections = resultsController.sections;
    id<NSFetchedResultsSectionInfo> const sectionInfo = sections.lastObject;
    NSUInteger const count = sectionInfo.numberOfObjects;
    return count;
}

- (UITableViewCell *)tableView:(UITableView *const)tableView
         cellForRowAtIndexPath:(NSIndexPath *const)indexPath
{
    NSFetchedResultsController *const resultsController = [self resultsControllerForTableView:tableView];
    NSString *const reuseIdentifier = NSStringFromClass(MRTableViewSubtitleCell.class);
    UITableViewCell *const cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    cell.textLabel.textColor = cell.detailTextLabel.textColor = UIColor.darkGrayColor;
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.textLabel.minimumScaleFactor = 0.9;
    cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
    cell.detailTextLabel.minimumScaleFactor = 0.9;
    MRSong *const song = [resultsController objectAtIndexPath:indexPath];
    [self configureCell:cell withObject:song];
    return cell;
}

    - (BOOL)tableView:(UITableView *const)tableView
canEditRowAtIndexPath:(NSIndexPath *const)indexPath
{
    BOOL canDelete;
    if (tableView == _tableView) {
        MRSong *const song = [_resultsController objectAtIndexPath:indexPath];
        canDelete = !song.isDetectingBpm;
    } else {
        canDelete = NO;
    }
    return canDelete;
}

 - (void)tableView:(UITableView *const)tableView
commitEditingStyle:(UITableViewCellEditingStyle const)editingStyle
 forRowAtIndexPath:(NSIndexPath *const)indexPath
{
    if (tableView == _tableView) {
        MRSong *const song = [_resultsController objectAtIndexPath:indexPath];
        if (!song.isDetectingBpm) {
            NSManagedObjectID *const objectID = song.objectID;
            MRLibraryStack *const sharedStack = MRLibraryStack.sharedStack;
            [sharedStack performSync:^(NSManagedObjectContext *moc) {
                NSError *existingError;
                MRSong *const song = [MRSong song:objectID inContext:moc withError:&existingError];
                [moc deleteObject:song];
                if (moc.hasChanges) {
                    NSError *saveError;
                    [moc save:&saveError];
                    MRNotErrorAssert(saveError);
                    [sharedStack persistChanges:&saveError];
                    MRNotErrorAssert(saveError);
                }
            }];
        }
    }
}
#pragma mark - UITableViewDelegate

      - (void)tableView:(UITableView *const)tableView
didSelectRowAtIndexPath:(NSIndexPath *const)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    UISearchDisplayController *const searchDisplayController = self.searchDisplayController;
    if (tableView == searchDisplayController.searchResultsTableView) {
        MRSong *const song = (MRSong *)[_searchResultsController objectAtIndexPath:indexPath];
        NSIndexPath *const tableViewIndexPath = [_resultsController indexPathForObject:song];
        if (tableViewIndexPath) {
            searchDisplayController.active = NO;
            [_tableView selectRowAtIndexPath:tableViewIndexPath
                                    animated:YES
                              scrollPosition:UITableViewScrollPositionTop];
        }
    }
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *const)controller
{
    UITableView *const tableView = [self tableViewForResultsController:controller];
    [tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *const)controller
   didChangeObject:(id const)anObject
       atIndexPath:(NSIndexPath *const)indexPath
     forChangeType:(NSFetchedResultsChangeType const)type
      newIndexPath:(NSIndexPath *const)newIndexPath
{
    UITableView *const tableView = [self tableViewForResultsController:controller];
    switch(type) {

        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[ newIndexPath ]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[ indexPath ]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [tableView reloadRowsAtIndexPaths:@[ indexPath ]
                             withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:@[ indexPath ]
                             withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:@[ newIndexPath ]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *const)controller
  didChangeSection:(id const)sectionInfo
           atIndex:(NSUInteger const)sectionIndex
     forChangeType:(NSFetchedResultsChangeType const)type
{
    UITableView *const tableView = [self tableViewForResultsController:controller];
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                     withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                     withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeMove: break;
        case NSFetchedResultsChangeUpdate: break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *const)controller
{
    UITableView *const tableView = [self tableViewForResultsController:controller];
    [tableView endUpdates];
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setUpTableContentInset];
    [self setUpTableViewContentOffsetAsync];
    [self registerTableViewCells];
    [self setUpResultsController];
}

- (void)viewWillAppear:(BOOL const)animated
{
    [super viewWillAppear:animated];
    [self configureVisibleCells];
    [self updateTabBarItemBadgeAsync];
}

#pragma mark - NSObject

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setUpBpmOperationQueue];
    [self registerApplicationNotifications];
}

- (void)dealloc
{
    [self unregisterApplicationNotifications];
}

@end
