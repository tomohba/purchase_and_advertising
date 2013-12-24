//
//  SBViewController.m
//  NendAdSample
//
//  Created by WADA KENJI on 2013/11/07.
//  Copyright (c) 2013年 Softbuild. All rights reserved.
//

#import "SBViewController.h"
#import "NADView.h"

@interface SBViewController () <NADViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *adView;

@end

@implementation SBViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    [self showNadView];
}

- (void)showNadView
{
    CGRect f = CGRectZero;
    f.size.width = NAD_ADVIEW_SIZE_320x50.width;
    f.size.height = NAD_ADVIEW_SIZE_320x50.height;
    
    NADView *nendView = [[NADView alloc] initWithFrame:f];
    [nendView setTag:19821012];
    [nendView setNendID:@"a6eca9dd074372c898dd1df549301f277c53f2b9"
                 spotID:@"3172"];
    [nendView setDelegate:self];
    [nendView load:nil];
    [self.adView addSubview:nendView];
}

#pragma mark - NADViewDelegate

// 広告素材の読み込みが完了したら送信される
- (void)nadViewDidFinishLoad:(NADView *)adView
{
    
}

@end
