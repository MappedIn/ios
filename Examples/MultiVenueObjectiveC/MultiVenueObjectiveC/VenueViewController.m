//
//  VenueViewController.m
//  MultiVenueObjectiveC
//
//  Created by Zachary Cregan on 2016-07-12.
//  Copyright © 2016 Zachary Cregan. All rights reserved.
//

#import "VenueViewController.h"
#import "MultiVenueObjectiveC-Swift.h"
#import "LocationTableViewController.h"

@interface VenueViewController ()

@property NSMutableArray *locations;

@end

@implementation VenueViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.venueSubview.alpha = 0;
    [self.loadingIndicator startAnimating];
    
    self.locations = [[NSMutableArray alloc] init];
    
    [MappedInWrapper getVenue:self.venueName callback:^ (NSArray *locations) {
        self.locations = [NSMutableArray arrayWithArray:locations];
        self.venueSubview.alpha = 1;
        [self.loadingIndicator stopAnimating];
    }];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier  isEqual: @"ShowLocations"]) {
        LocationTableViewController *locationTableView = segue.destinationViewController;
        locationTableView.locations = self.locations;
    }
    
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

@end
