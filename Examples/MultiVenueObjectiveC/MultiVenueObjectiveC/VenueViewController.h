//
//  VenueViewController.h
//  MultiVenueObjectiveC
//
//  Created by Zachary Cregan on 2016-07-12.
//  Copyright © 2016 Zachary Cregan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VenueViewController : UIViewController

@property NSString *venueName;
@property (weak, nonatomic) IBOutlet UIView *venueSubview;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicator;

@end
