//
//  NoConnectionViewController.h
//  Anteater Express
//
//  Created by Andrew Beier on 3/2/13.
//
//

#import <UIKit/UIKit.h>
#import "GAITrackedViewController.h"

@interface NoConnectionViewController : GAITrackedViewController    

- (IBAction)retryConnection:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *retryButton;

@end
