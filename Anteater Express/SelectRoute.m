//
//  SelectRoute.m
//  Anteater Express
//
//  Created by Andrew Beier on 5/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SelectRoute.h"
#import "ColorConverter.h"

@interface SelectRoute ()

@end

@implementation SelectRoute
@synthesize routesData; //NSArray
@synthesize routesList; //UITableView

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [[self navigationController] setNavigationBarHidden:NO animated:NO];
    
    self.routesList.dataSource = self;
    
    //To make sure the table view auto sizes
    self.routesList.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    self.routesList.delegate = self;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    NSInteger result = 0;
    if([tableView isEqual:self.routesList]){
        result = 1;
    }
    return result;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger result = 0;
    if([tableView isEqual:self.routesList]){
        switch (section) {
            case 0:
            {
                result = [routesData count];
                break;
            }
        }
    }
    return result;
}

- (UITableViewCell *) tableView:(UITableView *) tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString *CellIndentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIndentifier];
    
    if(cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIndentifier];
    }
    
    /*cell.textLabel.text = [NSString stringWithFormat:@"Section %ld, Cell %ld",
     (long)indexPath.section,
     (long)indexPath.row];*/
   // NSLog(@"CELL ROW: %d", indexPath.row);
    NSMutableDictionary* tempRoute = [routesData objectAtIndex: indexPath.row];
    //NSLog(@"Announcement Object: %@", tempRoute);
    cell.textLabel.text = [tempRoute valueForKey:@"Name"];
    cell.detailTextLabel.text = [tempRoute valueForKey:@"ColorName"];
    
    NSString* textHexColor = [tempRoute valueForKey:@"TextColorHex"];
    NSString* hexColor = [tempRoute valueForKey:@"ColorHex"];
    
    ColorConverter *colorConvert = [[ColorConverter alloc] init];
    
    cell.textLabel.textColor = [colorConvert colorWithHexString:textHexColor];
    cell.detailTextLabel.textColor = [colorConvert colorWithHexString:textHexColor];
    cell.textLabel.backgroundColor = [colorConvert colorWithHexString:hexColor];
    cell.detailTextLabel.backgroundColor = [colorConvert colorWithHexString:hexColor];
    cell.contentView.backgroundColor = [colorConvert colorWithHexString:hexColor];
    cell.backgroundColor = [colorConvert colorWithHexString:hexColor];
    
    return cell;
}

- (void)tableView: (UITableView *)tableView 
didSelectRowAtIndexPath: (NSIndexPath *)indexPath 
{
    NSMutableDictionary* tempRoute = [routesData objectAtIndex: indexPath.row];
    
   // NSLog(@"Data Content:  %@", tempRoute );
    
   // NSLog(@"ROUTE ID TO BE STORED: %i", routeID);
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    //Saving RouteID an int
    int routeID = [[tempRoute valueForKey:@"Id"] intValue];
    [prefs setInteger:routeID forKey:@"selectedRouteID"];
    
    UINavigationController *navController = self.navigationController;
    [navController popViewControllerAnimated:UIViewAnimationOptionTransitionFlipFromBottom];
    
	/*if (editController == nil) {
		self.editController = [[ItemEditViewController alloc] initWithNibName:@"ItemEditView" bundle:[NSBundle mainBundle]];
	}
	editController.dataItem =[dataItems objectAtIndex:idx];
	[self.view addSubview:[editController view]];*/
}

/*- (UIColor *) colorWithHexString: (NSString *) stringToConvert  
{  
    NSString *cString = [[stringToConvert stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];  
    
    // String should be 6 or 8 characters  
    if ([cString length] < 6) return nil;//DEFAULT_VOID_COLOR;  
    
    // strip 0X if it appears  
    if ([cString hasPrefix:@"0X"]) cString = [cString substringFromIndex:2];  
    
    if ([cString length] != 6) return nil;//DEFAULT_VOID_COLOR;  
    
    // Separate into r, g, b substrings  
    NSRange range;  
    range.location = 0;  
    range.length = 2;  
    NSString *rString = [cString substringWithRange:range];  
    
    range.location = 2;  
    NSString *gString = [cString substringWithRange:range];  
    
    range.location = 4;  
    NSString *bString = [cString substringWithRange:range];  
    
    // Scan values  
    unsigned int r, g, b;  
    [[NSScanner scannerWithString:rString] scanHexInt:&r];  
    [[NSScanner scannerWithString:gString] scanHexInt:&g];  
    [[NSScanner scannerWithString:bString] scanHexInt:&b];  
    
    return [UIColor colorWithRed:((float) r / 255.0f)  
                           green:((float) g / 255.0f)  
                            blue:((float) b / 255.0f)  
                           alpha:1.0f];  
}  */

@end
