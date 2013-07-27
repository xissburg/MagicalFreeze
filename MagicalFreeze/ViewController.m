//
//  ViewController.m
//  MagicalFreeze
//
//  Created by xissburg on 7/24/13.
//  Copyright (c) 2013 xissburg. All rights reserved.
//

#import "ViewController.h"
#import "MFDummy.h"

@interface ViewController () <NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, assign) NSUInteger chunkSize; // size of the chunks that are loaded on the table view
@property (nonatomic, assign) NSUInteger visibleChunk; // the index of the visible chunk of cells
@property (nonatomic, copy) NSArray *stringsArray; // array of strings that in an actualy app should come from a server on demand

@end

@implementation ViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.chunkSize = 40;
        
        // Fill the stringArray with random stuff
        NSString *characters = @"QWERTYUIOPASDFGHJKLZXCVBNMqwertyuiopasdfghjklzxcvbnm ";
        NSMutableArray *stringsArray = [[NSMutableArray alloc] init];
        for (int i = 0; i < 407; ++i) {
            NSUInteger length = 5 + arc4random_uniform(24);
            NSMutableString *randomString = [[NSMutableString alloc] initWithCapacity:length];
            for (int j = 0; j < length; ++j) {
                int k = arc4random_uniform(characters.length);
                [randomString appendString:[characters substringWithRange:NSMakeRange(k, 1)]];
            }
            [stringsArray addObject:[randomString copy]];
        }
        self.stringsArray = stringsArray;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.fetchedResultsController = [MFDummy fetchAllSortedBy:@"dummyId" ascending:YES withPredicate:nil groupBy:nil delegate:self];
    [self loadDummiesInChunk:0];
}

- (void)loadDummiesInChunk:(NSUInteger)chunk
{
    double delayInSeconds = 0.2 + (float)arc4random() / ((1LL<<32)-1) * 0.8; // Take up to 1 second per fake request
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            // Insert/update the requested chunk of items
            for (int i = chunk * self.chunkSize; i < chunk * self.chunkSize + self.chunkSize && i < self.stringsArray.count; ++i) {
                MFDummy *dummy = [MFDummy findFirstByAttribute:@"dummyId" withValue:@(i) inContext:localContext];
                if (dummy == nil) { // create if it doesn't exist
                    dummy = [MFDummy createInContext:localContext];
                    dummy.dummyId = @(i);
                }
                dummy.name = self.stringsArray[i];
            }
        } completion:^(BOOL success, NSError *error) {
            if (error) {
                NSLog(@"+[MagicalRecord saveWithBlock:completion:] %@", error);
            }
        }];
    });
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.fetchedResultsController.sections[0] numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DummyCell"];
    
    MFDummy *dummy = [self.fetchedResultsController objectAtIndexPath:indexPath];
    UILabel *label = (UILabel *)[cell viewWithTag:1839];
    label.text = [NSString stringWithFormat:@"%@: %@", dummy.dummyId, dummy.name];
    
    return cell;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // The visible chunk is computed based on the index of the last visible cell. The visible chunk changes whenever the index of the last
    // visible cell goes past the middle of the currently visible chunk.
    NSArray *indexPaths = [self.tableView indexPathsForVisibleRows];
    NSInteger lastIndex = [[indexPaths lastObject] row];
    NSUInteger visibleChunk = (lastIndex + self.chunkSize/2) / self.chunkSize;
    
    if (visibleChunk != self.visibleChunk) {
        self.visibleChunk = visibleChunk;
        [self loadDummiesInChunk:visibleChunk];
    }
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{    
    if (type == NSFetchedResultsChangeInsert) {
        NSLog(@"Insert row at index path %@", newIndexPath);
        [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    else if (type == NSFetchedResultsChangeDelete) {
        NSLog(@"Delete row at index path %@", indexPath);
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    else if (type == NSFetchedResultsChangeUpdate) {
        NSLog(@"Update row at index path %@", indexPath);
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    else if (type == NSFetchedResultsChangeMove) {
        NSLog(@"Move row at index path %@ to index path %@", indexPath, newIndexPath);
        [self.tableView moveRowAtIndexPath:indexPath toIndexPath:newIndexPath];
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

@end
