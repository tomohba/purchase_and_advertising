//
//  SBViewController.m
//  IAdSample
//
//  Created by WADA KENJI on 2013/10/31.
//  Copyright (c) 2013年 Softbuild. All rights reserved.
//

#import "SBViewController.h"
#import <iAd/iAd.h>

@interface SBViewController () <ADBannerViewDelegate>

@property (weak, nonatomic) IBOutlet ADBannerView *iAdBanner;
@property (weak, nonatomic) IBOutlet UIImageView *dummyBanner;

@end

@implementation SBViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // iAdBannerのデリゲートを設定する
    [self.iAdBanner setDelegate:self];

    // 起動時には
    self.iAdBanner.hidden = YES;
    self.dummyBanner.hidden = NO;
}

#pragma mark - ADBannerViewDelegate

// iAdの広告が読み込まれた
- (void)bannerViewDidLoadAd:(ADBannerView *)banner
{
    self.iAdBanner.hidden = NO;
    self.dummyBanner.hidden = YES;
}

// iAdの広告の読み込みに失敗した
- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    self.iAdBanner.hidden = YES;
    self.dummyBanner.hidden = NO;
}

- (BOOL)isBusy
{
    return NO;
}

// iAdの広告をクリックして、ユーザーにコンテンツを見せる直前の通知
- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave
{
    // アプリ側の都合で全画面に遷移させたくない場合
    if ([self isBusy]) {
        // NOを返すと、全画面広告へ遷移しない
        return NO;
    }
    
    // ゲームの場合、
    
    // YESを返すと、全画面広告へ遷移する
    return YES;
}

// ユーザーにコンテンツを見せる
- (void)bannerViewActionDidFinish:(ADBannerView *)banner
{
    // 元の画面に戻ってきた場合
}

@end
