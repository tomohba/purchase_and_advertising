//
//  ViewController.m
//  SinglePurchaseItem
//
//  Created by Tomonori Ohba on 2013/10/16.
//
//

#import "ViewController.h"
#import "ReceiptManager.h"
#import "SharedSecret.h"
#import "VerifyStoreReceipt.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
	// すてにプロダクトを購入済みか判定する
	NSString *latestReceiptStr = [[NSUserDefaults standardUserDefaults] stringForKey:@"latest_receipt"];
	if (latestReceiptStr != nil) {
		NSData *latestReceipt = [latestReceiptStr dataUsingEncoding:NSUTF8StringEncoding];
		NSTimeInterval expires = [[[NSUserDefaults standardUserDefaults] objectForKey:@"expires_date"] doubleValue] / 1000.0;
		if (expires < [[NSDate date] timeIntervalSince1970]) {
			// AutoRenewしているか確認
			ReceiptManager *receiptManager = [[ReceiptManager alloc] init];
			NSInteger status = [receiptManager verifyReceipt:latestReceipt
			                                    sharedSecret:@"8629289ea45940e0834ec7aebea65ea1"];
			if (status == 0) {
				// AutoRenewされている
				// 購入、リストアボタンを押下できないようにする
				[self.purchaseButton setEnabled:NO];
				[self.restoreButton setEnabled:NO];
			}
		}
		else {
			// 購入、リストアボタンを押下できないようにする
			[self.purchaseButton setEnabled:NO];
			[self.restoreButton setEnabled:NO];
		}
	}
    
	// アプリ内課金プロダクト情報を取得する
	myProduct = nil;
	myProductRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:@"AutoRenewableProduct7"]];
	myProductRequest.delegate = self;
	[myProductRequest start];
    
	// Indicatorを表示する
	[self.indicator setHidden:NO];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
    
	// AppDelegateからの購入通知を登録する
	[[NSNotificationCenter defaultCenter] addObserver:self
	                                         selector:@selector(purchased:)
	                                             name:@"Purchased"
	                                           object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
	                                         selector:@selector(failed:)
	                                             name:@"Failed"
	                                           object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
	                                         selector:@selector(purchaseCompleted:)
	                                             name:@"PurchaseCompleted"
	                                           object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
	                                         selector:@selector(restoreCompleted:)
	                                             name:@"RestoreCompleted"
	                                           object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
	                                         selector:@selector(restoreFailed:)
	                                             name:@"RestoreFailed"
	                                           object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
    
	// AppDelegateからの、購入通知を解除する
	[[NSNotificationCenter defaultCenter] removeObserver:self
	                                                name:@"Purchased"
	                                              object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self
	                                                name:@"Failed"
	                                              object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self
	                                                name:@"PurchaseCompleted"
	                                              object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self
	                                                name:@"RestoreCompleted"
	                                              object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self
	                                                name:@"RestoreFailed"
	                                              object:nil];
}

// SKProductsRequestDelegate
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
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
	NSString *localedPrice = [numberFormatter stringFromNumber:myProduct.price];
    
	// 商品情報を表示
	[self.productTitle setText:myProduct.localizedTitle];        // プロダクトのタイトル
	[self.productPrice setText:localedPrice];                    // ローカライズ後の金額
	[self.productDescription setText:myProduct.localizedDescription]; // プロダクトの説明
    
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
	[[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
    
	// Indicatorを表示する
	[self.indicator setHidden:NO];
}

- (IBAction)helloButtonOnTouch:(id)sender {
	// すてにプロダクトを購入済みか判定する
	NSTimeInterval expiresDate = [[NSUserDefaults standardUserDefaults] integerForKey:@"expires_date"];
    
	// 有効期間外
	if (expiresDate < [[NSDate date] timeIntervalSince1970]) {
		if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
			// iOS 6.1 or earlier.
			// AutoRenewしているか確認
			NSInteger status = 0;
			NSString *latestReceiptStr = [[NSUserDefaults standardUserDefaults] stringForKey:@"latest_receipt"];
			if (latestReceiptStr != nil) {
				NSData *latestReceipt = [latestReceiptStr dataUsingEncoding:NSUTF8StringEncoding];
				ReceiptManager *receiptManager = [[ReceiptManager alloc] init];
				status = [receiptManager verifyReceipt:latestReceipt
				                          sharedSecret:SHARED_SECRET];
				if (status == 0) {
					// AutoRenewされている
					// 購入、リストアボタンを押下できないようにする
					[self.purchaseButton setEnabled:NO];
					[self.restoreButton setEnabled:NO];
                    
					// 有効期間の日付文字列を取得する
					NSString *expires = [self expiresString];
					NSString *message = [NSString stringWithFormat:@"%@までご利用できます", expires];
					UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Hello!!"
					                                                message:message
					                                               delegate:nil
					                                      cancelButtonTitle:@"OK"
					                                      otherButtonTitles:nil];
					[alert show];
					return;
				}
			}
			// 購入、リストアボタンを押下できるようにする
			[self.purchaseButton setEnabled:YES];
			[self.restoreButton setEnabled:YES];
            
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"未購入です"
			                                                message:@"本機能は購入済みの方がご利用できます"
			                                               delegate:nil
			                                      cancelButtonTitle:@"OK"
			                                      otherButtonTitles:nil];
			[alert show];
		}
		else {
			// iOS 7
			NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
			BOOL result = verifyReceiptAtPath([receiptURL path]);
			if (result == YES) {
				NSDictionary *dict = dictionaryWithAppStoreReceipt([receiptURL path]);
				NSLog(@"%@", dict);
                
				ReceiptManager *receiptManager = [[ReceiptManager alloc] init];
				int status = [receiptManager savePurchaseInfo:dict];
                
				if (status == 0) {
					// AutoRenewされている
					// 購入、リストアボタンを押下できないようにする
					[self.purchaseButton setEnabled:NO];
					[self.restoreButton setEnabled:NO];
                    
					// 有効期間の日付文字列を取得する
					NSString *expires = [self expiresString];
					NSString *message = [NSString stringWithFormat:@"%@までご利用できます", expires];
					UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Hello!!"
					                                                message:message
					                                               delegate:nil
					                                      cancelButtonTitle:@"OK"
					                                      otherButtonTitles:nil];
					[alert show];
					return;
				}
				else if (status == 21006) { // 期限切れ
					receiptRequest = [[SKReceiptRefreshRequest alloc] init];
					receiptRequest.delegate = self;
					[receiptRequest start];
					return;
				}
			}
			// 購入、リストアボタンを押下できるようにする
			[self.purchaseButton setEnabled:YES];
			[self.restoreButton setEnabled:YES];
            
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"未購入です"
			                                                message:@"本機能は購入済みの方がご利用できます"
			                                               delegate:nil
			                                      cancelButtonTitle:@"OK"
			                                      otherButtonTitles:nil];
			[alert show];
		}
	}
	else {
		// 購入済み、有効期間の日付文字列を取得する
		NSString *expires = [self expiresString];
		NSString *message = [NSString stringWithFormat:@"%@までご利用できます", expires];
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Hello!!"
		                                                message:message
		                                               delegate:nil
		                                      cancelButtonTitle:@"OK"
		                                      otherButtonTitles:nil];
		[alert show];
	}
}

- (NSString *)expiresString {
	// 有効期限を表示するために設定から有効期限を取得、UNIX時間に変更する
	NSInteger expiresDate = [[NSUserDefaults standardUserDefaults] integerForKey:@"expires_date"];
    
	// UNIX時間（GMT）をロケールの時間で表示するための準備
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
	[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
	[dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
	[dateFormatter setLocale:[NSLocale currentLocale]];
	NSString *expiresStr = [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:expiresDate]];
    
	return expiresStr;
}

// レシートの更新完了
- (void)requestDidFinish:(SKRequest *)request {
	if (request  != receiptRequest) {
		return;
	}
    
	NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
	BOOL result = verifyReceiptAtPath([receiptURL path]);
	if (result == YES) {
		NSDictionary *dict = dictionaryWithAppStoreReceipt([receiptURL path]);
		NSLog(@"%@", dict);
        
		ReceiptManager *receiptManager = [[ReceiptManager alloc] init];
		int status = [receiptManager savePurchaseInfo:dict];
        
		if (status == 0) {
			// AutoRenewされている
			// 購入、リストアボタンを押下できないようにする
			[self.purchaseButton setEnabled:NO];
			[self.restoreButton setEnabled:NO];
            
			// 有効期間の日付文字列を取得する
			NSString *expires = [self expiresString];
			NSString *message = [NSString stringWithFormat:@"%@までご利用できます", expires];
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Hello!!"
			                                                message:message
			                                               delegate:nil
			                                      cancelButtonTitle:@"OK"
			                                      otherButtonTitles:nil];
			[alert show];
			return;
		}
	}
	// 購入、リストアボタンを押下できるようにする
	[self.purchaseButton setEnabled:YES];
	[self.restoreButton setEnabled:YES];
    
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"未購入です"
	                                                message:@"本機能は購入済みの方がご利用できます"
	                                               delegate:nil
	                                      cancelButtonTitle:@"OK"
	                                      otherButtonTitles:nil];
	[alert show];
}

- (void)purchased:(NSNotification *)notification {
	// 購入、リストアボタンを押下できないようにする
	[self.purchaseButton setEnabled:NO];
	[self.restoreButton setEnabled:NO];
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

@end
