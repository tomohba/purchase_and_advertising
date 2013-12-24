//
//  SBViewController.m
//  AdMobSample
//
//  Created by WADA KENJI on 2013/09/18.
//  Copyright (c) 2013年 Softbuild. All rights reserved.
//

#import "SBViewController.h"

// GADBannerViewの定義をインポートする
#import "GADBannerView.h"

@interface SBViewController ()

@property (nonatomic, strong) GADBannerView *bannerView;

@end

#pragma mark -

@implementation SBViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    // バナー広告を画面下部に表示させるために座標を計算する
    CGFloat y = self.view.bounds.size.height - GAD_SIZE_320x50.height;
    CGRect bannerFrame
        = CGRectMake(0, y, GAD_SIZE_320x50.width, GAD_SIZE_320x50.height);
    
    // バナーのサイズを指定して、GADBannerViewオブジェクトを生成する
    self.bannerView = [[GADBannerView alloc] initWithFrame:bannerFrame];
    
    // 広告の「ユニット ID」を指定する。これは AdMob パブリッシャー ID です。
    self.bannerView.adUnitID = @"ca-app-pub-6275292186973463/7555808831";
    
    // 広告表示から戻ってくるViewControllerを指定する
    self.bannerView.rootViewController = self;
    
    // バナー広告をViewControllerのviewに追加する
    [self.view addSubview:self.bannerView];
    
    // 無効なインプレッションが発生しないように
    // リクエスト情報のテストデバイス一覧にシミュレータのIDを追加する
    GADRequest *request = [GADRequest request];
    request.testDevices = @[GAD_SIMULATOR_ID];
    
    // Google AdMobへ広告を要求する
    [self.bannerView loadRequest:request];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
