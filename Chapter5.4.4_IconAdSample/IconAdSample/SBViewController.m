//
//  SBViewController.m
//

#import "SBViewController.h"
#import <MrdIconSDK/MrdIconSDK.h> // for アスタ

@interface SBViewController ()
@property (weak, nonatomic) IBOutlet UIView *iconAdView;
@property (strong, nonatomic) MrdIconLoader* iconLoader;
@end

@implementation SBViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.iconLoader = [[MrdIconLoader alloc] init];
    CGRect frame = CGRectMake(0, 0, 75, 75);
    MrdIconCell* iconCell = [[MrdIconCell alloc] initWithFrame:frame];
    [self.iconLoader addIconCell:iconCell];
    [self.iconAdView addSubview:iconCell];
    [self.iconLoader startLoadWithMediaCode: @"__TEST__"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
