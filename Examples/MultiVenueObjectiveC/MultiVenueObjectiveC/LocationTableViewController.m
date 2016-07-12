//
//  LocationTableViewController.m
//  MultiVenueObjectiveC
//
//  Created by Zachary Cregan on 2016-07-12.
//  Copyright © 2016 Zachary Cregan. All rights reserved.
//

#import "LocationTableViewController.h"
#import "MultiVenueObjectiveC-Swift.h"
#import "LocationTableViewCell.h"

@implementation LocationTableViewController

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.locations count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LocationTableViewCell" forIndexPath:indexPath];
    
    NSString *location = [self.locations objectAtIndex:indexPath.row];
    cell.textLabel.text = location;
    
    return cell;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier  isEqual: @"SelectLocation"]) {
        MapViewController *mapViewController = segue.destinationViewController;
        LocationTableViewCell *selectedLocationCell = sender;
        NSIndexPath *indexPath = [self.tableView indexPathForCell:selectedLocationCell];
        NSString *selectedLocation = [self.locations objectAtIndex:indexPath.row];
        [mapViewController selectLocationByName:selectedLocation];
    }
    
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

@end
