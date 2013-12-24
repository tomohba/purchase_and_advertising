//
//  AppDelegate.m
//  SinglePurchaseItem
//
//  Created by Tomonori Ohba on 2013/10/16.
//
//

#import "AppDelegate.h"
#import "ReceiptManager.h"
#import "SharedSecret.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	// updatedTransactionsを受け取るための登録
	[[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    
	// すてにプロダクトを購入済みか判定する
	NSString *latestReceiptStr = [[NSUserDefaults standardUserDefaults] stringForKey:@"latest_receipt"];
	if (latestReceiptStr != nil) {
		NSData *latestReceipt = [latestReceiptStr dataUsingEncoding:NSUTF8StringEncoding];
		NSTimeInterval expires = [[[NSUserDefaults standardUserDefaults] objectForKey:@"expires_date"] doubleValue] / 1000.0;
		if (expires < [[NSDate date] timeIntervalSince1970]) {
			// AutoRenewしているか確認
			ReceiptManager *receiptManager = [[ReceiptManager alloc] init];
			[receiptManager verifyReceipt:latestReceipt
			                 sharedSecret:SHARED_SECRET];
		}
	}
    
	return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
	// updatedTransactionsを受け取るための登録
	[[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
	// updatedTransactionsの解除
	[[SKPaymentQueue defaultQueue] addTransactionObserver:self];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
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
                //                NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
                //                NSData *receiptdata = [NSData dataWithContentsOfURL:receiptURL];
                //                NSData *receipt = [receiptdata base64EncodedDataWithOptions:0];
				NSData *receipt = [transaction.transactionReceipt base64EncodedDataWithOptions:0];
				ReceiptManager *receiptManager = [[ReceiptManager alloc] init];
				NSInteger status = [receiptManager verifyReceipt:receipt
				                                    sharedSecret:SHARED_SECRET];
				if (status == 0) {
					// 購入処理成功したことを通知する
					[[NSNotificationCenter defaultCenter] postNotificationName:@"Purchased"
					                                                    object:transaction];
				}
				else {
					// 購入処理エラーを通知する
					[[NSNotificationCenter defaultCenter] postNotificationName:@"Failed"
					                                                    object:transaction];
				}
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
				NSString *errormsg = [NSString stringWithFormat:@"%@ [%ld]",
				                      error.localizedDescription,
				                      (long)error.code];
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
                
				// 購入処理エラーを通知する
				[[NSNotificationCenter defaultCenter] postNotificationName:@"Failed"
				                                                    object:transaction];
                
				break;
			}
                
                // リストア
			case SKPaymentTransactionStateRestored:
			{
				NSLog(@"SKPaymentTransactionStateRestored");
				// リストア処理完了
				//                NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
				//                NSData *receiptdata = [NSData dataWithContentsOfURL:receiptURL];
				//                NSData *receipt = [receiptdata base64EncodedDataWithOptions:0];
				NSData *receipt = [transaction.transactionReceipt base64EncodedDataWithOptions:0];
				ReceiptManager *receiptManager = [[ReceiptManager alloc] init];
				NSInteger status = [receiptManager verifyReceipt:receipt
				                                    sharedSecret:SHARED_SECRET];
				if (status == 0) {
					// 購入処理成功したことを通知する
					[[NSNotificationCenter defaultCenter] postNotificationName:@"Purchased"
					                                                    object:transaction];
				}
				else {
					// 購入処理エラーを通知する
					[[NSNotificationCenter defaultCenter] postNotificationName:@"Failed"
					                                                    object:transaction];
				}
				[queue finishTransaction:transaction];
				break;
			}
                
			default:
				break;
		}
	}
}

// 購入処理の終了
- (void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray *)transactions {
	NSLog(@"paymentQueue:removedTransactions");
    
	// 購入処理が全て成功したことを通知する
	[[NSNotificationCenter defaultCenter] postNotificationName:@"PurchaseCompleted"
	                                                    object:transactions];
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
	// 全てのリストア処理が終了
	NSLog(@"paymentQueueRestoreCompletedTransactionsFinished");
    
	// 全てのリストア処理が終了したことを通知する
	[[NSNotificationCenter defaultCenter] postNotificationName:@"RestoreCompleted"
	                                                    object:queue];
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
	// リストアの失敗
	NSLog(@"restoreCompletedTransactionsFailedWithError %@ [%ld]",
	      error.localizedDescription,
	      (long)error.code);
    
	// リストアが失敗したことを通知する
	[[NSNotificationCenter defaultCenter] postNotificationName:@"RestoreFailed"
	                                                    object:error];
}

@end
