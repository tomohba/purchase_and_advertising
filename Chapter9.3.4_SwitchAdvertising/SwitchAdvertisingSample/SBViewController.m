//
//  SBViewController.m
//  SwitchAdvertisingSample
//
//  Created by WADA KENJI on 2013/11/07.
//  Copyright (c) 2013年 Softbuild. All rights reserved.
//

#import "SBViewController.h"
#import "NADView.h"
#import "GADBannerView.h"

@interface SBViewController () <NADViewDelegate, GADBannerViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *adView;

@end

@implementation SBViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    
    [self refreshAds];
}

// 広告の表示を更新する
- (void)refreshAds
{
    NSURL* url = [NSURL URLWithString:@"http://baseball.softbuild.jp/advertising_switcher.json"];
    [NSURLConnection sendAsynchronousRequest:[NSMutableURLRequest requestWithURL:url]
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse* response, NSData* data, NSError* error) {
                               [self didFinishedDownload:response data:data error:error];
                           }];
}

// 広告定義をダウンロードして、定義に応じた広告を表示させる
- (void)didFinishedDownload:(NSURLResponse *)response data:(NSData *)data error:(NSError *)error
{
    if (error) {
        // 広告定義の取得に失敗したので広告を非表示にする
        self.adView.hidden = YES;
        return;
    }
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    if ([httpResponse statusCode] != 200) {
        // 広告定義のダウンロードに失敗したので広告を非表示にする
        self.adView.hidden = YES;
        return;
    }
    
    // ダウンロードしたJSONデータのパースする
    NSError* perseError = nil;
    id json = [NSJSONSerialization JSONObjectWithData:data
                                              options:kNilOptions error:&perseError];
    if (perseError) {
        // 広告定義のパースに失敗したので広告を非表示にする
        self.adView.hidden = YES;
        return;
    }
    
    // 既に広告が表示されていれば、それを取得してSuperViewから削除する
    UIView *view = [self.adView viewWithTag:19821012];
    [view removeFromSuperview];
    
    // JSONファイルから定義を取り出す
    NSString *adtype = [json objectForKey:@"enable_advertising"];
    if ([adtype isEqualToString:@"appbank"]) {
        
        // AppBank Networkの広告を表示させる
        [self showNadView];
        
    } else if ([adtype isEqualToString:@"admob"]) {
        
        // Google AdMobの広告を表示させる
        [self showAdMobView];
        
    } else {
        // 想定外の広告定義値だったので広告を非表示にする
        self.adView.hidden = YES;
    }
}



- (void)showNadView
{
    CGRect f = CGRectZero;
    f.size.width = NAD_ADVIEW_SIZE_320x50.width;
    f.size.height = NAD_ADVIEW_SIZE_320x50.height;
    
    NADView *nendView = [[NADView alloc] initWithFrame:f];
    [nendView setTag:19821012];
    [nendView setNendID:@"a6eca9dd074372c898dd1df549301f277c53f2b9" spotID:@"3172"];
    [nendView setDelegate:self];
    [nendView load:nil];
    [self.adView addSubview:nendView];
}

- (void)showAdMobView
{
    GADBannerView *adMobView = [[GADBannerView alloc] initWithAdSize:kGADAdSizeBanner];
    [adMobView setTag:19821012];
    [adMobView setAdUnitID:@"ca-app-pub-XXXXXXXXXXXXXXXXXXXXXXX"];
    [adMobView setRootViewController:self];
    [adMobView setDelegate:self];
    [adMobView loadRequest:[GADRequest request]];
    [self.adView addSubview:adMobView];
}

#pragma mark - AppBank Network SDKのデリゲート


- (void)nadViewDidFinishLoad:(NADView *)adView
{
    // 広告の表示に成功したのでadViewを表示させる
    self.adView.hidden = NO;
}

- (void)nadViewDidFailToReceiveAd:(NADView *)adView
{
    // 広告定義のパースに失敗したのでadViewを非表示にする
    self.adView.hidden = YES;
}

#pragma mark - Nend AppBank Network SDKのデリゲート

-(void)adViewDidReceiveAd:(GADBannerView *)view
{
    // 広告の表示に成功したのでadViewを表示させる
    self.adView.hidden = NO;
}

-(void)adView:(GADBannerView *)view didFailToReceiveAdWithError:(GADRequestError *)error
{
    // 広告定義のパースに失敗したのでadViewを非表示にする
    self.adView.hidden = YES;
}

@end
