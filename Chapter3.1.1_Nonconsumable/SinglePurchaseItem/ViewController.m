//
//  ViewController.m
//  SinglePurchaseItem
//
//  Created by Tomonori Ohba on 2013/10/16.
//
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
	// すてにプロダクトを購入済みか判定する
	BOOL isPurchased = [[NSUserDefaults standardUserDefaults] boolForKey:@"NonConsumableProduct"];
	if (isPurchased == YES) {
		// 購入済み、金額表示を購入済みに
		[self.productPrice setText:@"購入済み"];
		// 購入、リストアボタンを押下できないようにする
		[self.purchaseButton setEnabled:NO];
		[self.restoreButton setEnabled:NO];
	}
	else {
		// アプリ内課金プロダクト情報を取得する
		myProduct = nil;
		myProductRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:@"NonConsumableProduct"]];
		myProductRequest.delegate = self;
		[myProductRequest start];
	}
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // updatedTransactionsを受け取るための登録
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // updatedTransactionsの解除
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

// SKProductsRequestDelegate
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
	// アプリ内課金プロダクトが取得できなかった
	if (response == nil) {
		NSLog(@"didReceiveResponse response == nil");
		[self.productTitle setText:@"購入できるものはありません"];
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
}

// 購入処理の終了
- (void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray *)transactions {
	NSLog(@"paymentQueue:removedTransactions");
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
	// リストアの失敗
	NSLog(@"restoreCompletedTransactionsFailedWithError %@ [%ld]", error.localizedDescription, (long)error.code);
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
	// 全てのリストア処理が終了
	NSLog(@"paymentQueueRestoreCompletedTransactionsFinished");
}

// StoreKit
// 購入、リストアなどのトランザクションの都度、通知される
- (void)   paymentQueue:(SKPaymentQueue *)queue
    updatedTransactions:(NSArray *)transactions {
	NSLog(@"paymentQueue:updatedTransactions");
	for (SKPaymentTransaction *transaction in transactions) {
		switch (transaction.transactionState) {
                // 購入処理中
			case SKPaymentTransactionStatePurchasing:
			{
				NSLog(@"SKPaymentTransactionStatePurchasing");
				break;
			}
                
                // 購入処理完了
			case SKPaymentTransactionStatePurchased:
			{
				NSLog(@"SKPaymentTransactionStatePurchased");
				// ここに購入完了時の処理を追加する
				// 設定にプロダクトIDを保持
				[[NSUserDefaults standardUserDefaults] setBool:YES
				                                        forKey:transaction.payment.productIdentifier];
				[[NSUserDefaults standardUserDefaults] synchronize];
                
				// 購入済み表示
				// UIの表示を変更
				// 金額表示を購入済みに
				[self.productPrice setText:@"購入済み"];
				// 購入、リストアボタンを押下できないようにする
				[self.purchaseButton setEnabled:NO];
				[self.restoreButton setEnabled:NO];
                
				[queue finishTransaction:transaction];
				break;
			}
                
                // 購入処理エラー
                // ユーザが購入処理をキャンセルした場合も含む
			case SKPaymentTransactionStateFailed:
			{
				NSLog(@"SKPaymentTransactionStateFailed");
				[queue finishTransaction:transaction];
                
				// エラーメッセージを表示
				NSError *error = transaction.error;
				NSString *errormsg = [NSString stringWithFormat:@"%@ [%ld]", error.localizedDescription, (long)error.code];
				[[[UIAlertView alloc] initWithTitle:@"エラー"
				                            message:errormsg
				                           delegate:nil
				                  cancelButtonTitle:@"OK"
				                  otherButtonTitles:nil] show];
                
				// エラーの詳細
				// 支払いがキャンセルされた
				if (transaction.error.code != SKErrorPaymentCancelled) {
					NSLog(@"SKPaymentTransactionStateFailed - SKErrorPaymentCancelled");
				}
				// 請求先情報の入力画面に移り、購入処理が強制終了した
				else if (transaction.error.code == SKErrorUnknown) {
					NSLog(@"SKPaymentTransactionStateFailed - SKErrorUnknown");
				}
				// その他エラー
				else {
					NSLog(@"SKPaymentTransactionStateFailed - error.code:%ld",
					      (long)transaction.error.code);
				}
				break;
			}
                
			default:
				break;
		}
	}
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
}

- (IBAction)restoreButtonOnTouch:(id)sender {
}

- (IBAction)helloButtonOnTouch:(id)sender {
	// すてにプロダクトを購入済みか判定する
	BOOL isPurchased = [[NSUserDefaults standardUserDefaults] boolForKey:@"NonConsumableProduct"];
	if (isPurchased == YES) {
		// 購入済み
		// ここではサンプルとして、Alertの表示を変えている
		[[[UIAlertView alloc] initWithTitle:@"Hello!!"
		                            message:@"ようこそ！"
		                           delegate:nil
		                  cancelButtonTitle:@"OK"
		                  otherButtonTitles:nil] show];
	}
	else {
		[[[UIAlertView alloc] initWithTitle:@"未購入です"
		                            message:@"本機能は購入済みの方がご利用できます"
		                           delegate:nil
		                  cancelButtonTitle:@"OK"
		                  otherButtonTitles:nil] show];
	}
}

@end
