//
//  ViewController.m
//  iAd-Purchase
//
//  Created by Tomonori Ohba on 2013/11/12.
//  Copyright (c) 2013年 Purchase and Advertising. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // すてにプロダクトを購入済みか判定する
    BOOL isPurchased =
    [[NSUserDefaults standardUserDefaults] boolForKey:@"HideAds"];
    if (isPurchased == YES) {
        // 購入済み、金額表示を購入済みに
        [self.purchaseButton setTitle:@"購入済み"
                             forState:UIControlStateNormal];
        // 購入、リストアボタンを押下できないようにする
        [self.purchaseButton setEnabled:NO];
        [self.restoreButton setEnabled:NO];
        // 広告を非表示にする
        [self.iAdBanner setHidden:YES];
        [self.dummyBanner setHidden:YES];
    }
    else {
        // iAdBannerのデリゲートを設定する
        [self.iAdBanner setDelegate:self];
        
        // 起動時には
        [self.iAdBanner setHidden:YES];
        [self.dummyBanner setHidden:NO];
        
        // アプリ内課金プロダクト情報を取得する
        myProduct = nil;
        myProductRequest =
        [[SKProductsRequest alloc]
         initWithProductIdentifiers:
         [NSSet setWithObject:@"HideAds"]];
        myProductRequest.delegate = self;
        [myProductRequest start];
        
        // Indicatorを表示する
        [self.indicator setHidden:NO];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // AppDelegateからの購入通知を登録する
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
           selector:@selector(purchased:)
               name:@"Purchased"
             object:nil];
    [nc addObserver:self
           selector:@selector(restored:)
               name:@"Restored"
             object:nil];
    [nc addObserver:self
           selector:@selector(failed:)
               name:@"Failed"
             object:nil];
    [nc addObserver:self
           selector:@selector(purchaseCompleted:)
               name:@"PurchaseCompleted"
             object:nil];
    [nc addObserver:self
           selector:@selector(restoreCompleted:)
               name:@"RestoreCompleted"
             object:nil];
    [nc addObserver:self
           selector:@selector(restoreFailed:)
               name:@"RestoreFailed"
             object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // AppDelegateからの、購入通知を解除する
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self
                  name:@"Purchased"
                object:nil];
    [nc removeObserver:self
                  name:@"Restored"
                object:nil];
    [nc removeObserver:self
                  name:@"Failed"
                object:nil];
    [nc removeObserver:self
                  name:@"PurchaseCompleted"
                object:nil];
    [nc removeObserver:self
                  name:@"RestoreCompleted"
                object:nil];
    [nc removeObserver:self
                  name:@"RestoreFailed"
                object:nil];
}

// SKProductsRequestDelegate
- (void)productsRequest:(SKProductsRequest *)request
     didReceiveResponse:(SKProductsResponse *)response {
    // アプリ内課金プロダクトが取得できなかった
    if (response == nil) {
        NSLog(@"didReceiveResponse response == nil");
        [self.productTitle setText:@"購入できるものはありません"];
        
        // Indicatorを非表示にする
        [self.indicator setHidden:YES];
        
        return;
    }
    
    // 確認できなかったidentifierをログに記録
    for (NSString *identifier in response.invalidProductIdentifiers) {
        NSLog(@"invalidProductIdentifiers: %@", identifier);
    }
    
    // アプリ内課金プロダクトを取得
    for (SKProduct *product in response.products) {
        NSLog(@"Product: %@ %@ %@ %d",
              product.productIdentifier,
              product.localizedTitle,
              product.localizedDescription,
              [product.price intValue]);
        
        // ここではアプリ内課金プロダクトが唯一である想定
        myProduct = product;
    }
    
    // 商品情報が1つも取得できなかった
    if (myProduct == nil) {
        NSLog(@"myProduct == nil");
        [self.productTitle setText:@"購入できるものはありません"];
        
        // Indicatorを非表示にする
        [self.indicator setHidden:YES];
        
        return;
    }
    
    // ローカライズ後の価格を取得
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [numberFormatter setLocale:myProduct.priceLocale];
    NSString *localedPrice =
    [numberFormatter stringFromNumber:myProduct.price];
    
    // 商品情報を表示
    // プロダクトのタイトル
    [self.productTitle setText:myProduct.localizedTitle];
    // ローカライズ後の金額
    [self.purchaseButton setTitle:
     [NSString stringWithFormat:@"%@で購入する", localedPrice]
                         forState:UIControlStateNormal];
    // プロダクトの説明
    [self.productDescription setText:myProduct.localizedDescription];
    
    // Indicatorを非表示にする
    [self.indicator setHidden:YES];
}

- (IBAction)purchaseButtonOnTouch:(id)sender {
    // 機能制限 - App内の購入　のチェックを行う
    if ([SKPaymentQueue canMakePayments] == NO) {
        UIAlertView *alert =
        [[UIAlertView alloc] initWithTitle:@"購入できません"
                                   message:@"App内の購入が機能制限されています"
                                  delegate:nil
                         cancelButtonTitle:@"OK"
                         otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    // 購入用のペイメントをSKProductから生成する
    SKPayment *payment = [SKPayment paymentWithProduct:myProduct];
    // SKPaymentQueueに追加＝トランザクションが開始される
    [[SKPaymentQueue defaultQueue] addPayment:payment];
    
    // Indicatorを表示する
    [self.indicator setHidden:NO];
}

- (IBAction)restoreButtonOnTouch:(id)sender {
    // リストアを開始
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
    
    // Indicatorを表示する
    [self.indicator setHidden:NO];
}

- (void)purchased:(NSNotification *)notification {
    // 購入済み表示
    // UIの表示を変更
    // 金額表示を購入済みに
    [self.purchaseButton setTitle:@"購入済み" forState:UIControlStateNormal];
    // 購入、リストアボタンを押下できないようにする
    [self.purchaseButton setEnabled:NO];
    [self.restoreButton setEnabled:NO];
    // 広告を非表示にする
    [self.iAdBanner setHidden:YES];
    [self.dummyBanner setHidden:YES];
}

- (void)restored:(NSNotification *)notification {
    // 購入済み表示
    // UIの表示を変更
    // 金額表示を購入済みに
    [self.purchaseButton setTitle:@"購入済み" forState:UIControlStateNormal];
    // 購入、リストアボタンを押下できないようにする
    [self.purchaseButton setEnabled:NO];
    [self.restoreButton setEnabled:NO];
    // 広告を非表示にする
    [self.iAdBanner setHidden:YES];
    [self.dummyBanner setHidden:YES];
}

- (void)failed:(NSNotification *)notification {
    // Indicatorを非表示にする
    [self.indicator setHidden:YES];
}

- (void)purchaseCompleted:(NSNotification *)notification {
    // Indicatorを非表示にする
    [self.indicator setHidden:YES];
}

- (void)restoreCompleted:(NSNotification *)notification {
    // Indicatorを非表示にする
    [self.indicator setHidden:YES];
}

- (void)restoreFailed:(NSNotification *)notification {
    // Indicatorを非表示にする
    [self.indicator setHidden:YES];
}

#pragma mark - ADBannerViewDelegate

// iAdの広告が読み込まれた
- (void)bannerViewDidLoadAd:(ADBannerView *)banner {
    // 広告非表示プロダクトを購入していない場合は実行する
    BOOL isPurchased =
    [[NSUserDefaults standardUserDefaults] boolForKey:@"HideAds"];
    if (isPurchased == NO) {
        self.iAdBanner.hidden = NO;
        self.dummyBanner.hidden = YES;
    }
}

// iAdの広告の読み込みに失敗した
- (void)bannerView:(ADBannerView *)banner
    didFailToReceiveAdWithError:(NSError *)error {    
    // 広告非表示プロダクトを購入していない場合は実行する
    BOOL isPurchased =
    [[NSUserDefaults standardUserDefaults] boolForKey:@"HideAds"];
    if (isPurchased == NO) {
        self.iAdBanner.hidden = YES;
        self.dummyBanner.hidden = NO;
    }
}

- (BOOL)isBusy {
    return NO;
}

// iAdの広告をクリックして、ユーザーにコンテンツを見せる直前の通知
- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner
               willLeaveApplication:(BOOL)willLeave {
    // アプリ側の都合で全画面に遷移させたくない場合
    if ([self isBusy]) {
        // NOを返すと、全画面広告へ遷移しない
        return NO;
    }
    
    // YESを返すと、全画面広告へ遷移する
    return YES;
}

// ユーザーにコンテンツを見せる
- (void)bannerViewActionDidFinish:(ADBannerView *)banner {
    // 元の画面に戻ってきた場合
}

@end
