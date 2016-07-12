//
//  VenueViewController.m
//  MultiVenueObjectiveC
//
//  Created by Zachary Cregan on 2016-07-12.
//  Copyright © 2016 Zachary Cregan. All rights reserved.
//

#import "VenueViewController.h"
#import "MultiVenueObjectiveC-Swift.h"

@interface VenueViewController ()

@property NSString *venueName;
@property NSMutableArray *locations;

@end

@implementation VenueViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.venueSubview.alpha = 0;
    [self.loadingIndicator startAnimating];
    
    self.locations = [[NSMutableArray alloc] init];
    
    [MappedInWrapper getVenue:self.venueName callback:^ (NSArray *locations) {
        self.locations = locations;
        self.venueSubview.alpha = 1;
        [self.loadingIndicator stopAnimating];
    }];
}

@end
