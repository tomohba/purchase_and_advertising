//
//  SBViewController.m
//  AdMobInterstitialSample
//
//  Created by WADA KENJI on 2013/11/04.
//  Copyright (c) 2013年 Softbuild. All rights reserved.
//

#import "SBViewController.h"
#import "GADInterstitial.h"

@interface SBViewController () <GADInterstitialDelegate>

@property (nonatomic, strong) GADInterstitial *interstitial;

@end

@implementation SBViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)showAd:(id)sender
{
    self.interstitial = [[GADInterstitial alloc] init];
    [self.interstitial setDelegate:self];
    [self.interstitial setAdUnitID:@"ca-app-pub-6275292186973463/1389583638"];
    [self.interstitial loadRequest:[GADRequest request]];
}

#pragma mark - GADInterstitialDelegate

// インタースティシャル
- (void)interstitialDidReceiveAd:(GADInterstitial *)ad
{
    [self.interstitial presentFromRootViewController:self];
}

- (void)interstitial:(GADInterstitial *)ad
    didFailToReceiveAdWithError:(GADRequestError *)error
{
    self.interstitial = nil;
}

//
- (void)interstitialDidDismissScreen:(GADInterstitial *)ad
{
    
}

@end
