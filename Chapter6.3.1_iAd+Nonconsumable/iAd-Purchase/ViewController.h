//
//  ViewController.h
//  iAd-Purchase
//
//  Created by Tomonori Ohba on 2013/11/12.
//  Copyright (c) 2013年 Purchase and Advertising. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <iAd/iAd.h>
#import <StoreKit/StoreKit.h>

@interface ViewController : UIViewController
<ADBannerViewDelegate, SKProductsRequestDelegate> {
	SKProductsRequest *myProductRequest; // プロダクト情報リクエスト用
	SKProduct *myProduct;                // 取得したプロダクト情報
}

@property (weak, nonatomic) IBOutlet ADBannerView *iAdBanner;
@property (weak, nonatomic) IBOutlet UIImageView *dummyBanner;

@property (weak, nonatomic) IBOutlet UILabel *productTitle;
@property (weak, nonatomic) IBOutlet UILabel *productDescription;
@property (weak, nonatomic) IBOutlet UIButton *purchaseButton;
@property (weak, nonatomic) IBOutlet UIButton *restoreButton;

@property (weak, nonatomic) IBOutlet UIView *indicator;

- (IBAction)purchaseButtonOnTouch:(id)sender;
- (IBAction)restoreButtonOnTouch:(id)sender;

@end
