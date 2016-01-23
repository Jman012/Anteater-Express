//
//  AERouteInfoViewController.m
//  Anteater Express
//
//  Created by James Linnell on 1/22/16.
//
//

#import "AERouteInfoViewController.h"

@interface AERouteInfoViewController ()

@property (nonatomic, strong) IBOutlet UIView *colorView;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UILabel *descriptionLabel;
@property (nonatomic, strong) IBOutlet UILabel *fareLabel;

@property (nonatomic, strong) IBOutlet UISegmentedControl *scheduleSegmentedControl;
@property (nonatomic, strong) IBOutlet UITextView *scheduleTextView;

@end

@implementation AERouteInfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
