//
//  AppDelegate.m
//  SinglePurchaseItem
//
//  Created by Tomonori Ohba on 2013/10/16.
//
//

#import "AppDelegate.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	// updatedTransactionsを受け取るための登録
	[[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    
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
				// レシートの確認とダウンロード処理
				[self verifyReceipt:transaction.transactionReceipt];
				// 購入処理成功したことを通知する
				[[NSNotificationCenter defaultCenter] postNotificationName:@"Purchased"
				                                                    object:transaction];
                
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
				NSString *errormsg = [NSString stringWithFormat:@"%@ [%ld]", error.localizedDescription, error.code];
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
					      transaction.error.code);
				}
                
				// 購入処理エラーを通知する
				[[NSNotificationCenter defaultCenter] postNotificationName:@"Failed"
				                                                    object:transaction];
                
				break;
			}
                
			case SKPaymentTransactionStateRestored:
			{
				NSLog(@"SKPaymentTransactionStateRestored");
				// リストア処理完了
				// 設定にプロダクトIDを保持
				[[NSUserDefaults standardUserDefaults] setBool:YES
				                                        forKey:transaction.payment.productIdentifier];
				[[NSUserDefaults standardUserDefaults] synchronize];
                
				// リストアが成功したこと（＝購入成功）を通知する
				[[NSNotificationCenter defaultCenter] postNotificationName:@"Restored"
				                                                    object:transaction];
                
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
	NSLog(@"restoreCompletedTransactionsFailedWithError %@ [%ld]", error.localizedDescription, error.code);
    
	// リストアが失敗したことを通知する
	[[NSNotificationCenter defaultCenter] postNotificationName:@"RestoreFailed"
	                                                    object:error];
}

- (void)verifyReceipt:(NSData *)receipt {
	NSString *base64 = [receipt base64EncodedStringWithOptions:0];
	NSString *body = [NSString stringWithFormat:@"tran=%@", base64];
    
	// リクエストオブジェクトを生成
	NSString *urlstr = @"http://192.168.0.4/YourServer/RequestProduct.aspx";
	NSURL *url = [NSURL URLWithString:urlstr];
	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
	[req setHTTPMethod:@"POST"];
	[req setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    
	// レスポンスオブジェクト
	NSURLResponse *resp;
	// エラーオブジェクト
	NSError *err;
	// 同期的HTTP通信
	NSData *result = [NSURLConnection sendSynchronousRequest:req
	                                       returningResponse:&resp
	                                                   error:&err];
    
	if (result != nil) {
		NSString *product = [[NSString alloc] initWithData:result encoding:NSASCIIStringEncoding];
		long getItemCount = [product longLongValue];
		long itemCount = [[NSUserDefaults standardUserDefaults] integerForKey:@"ConsumableProduct"];
        
		// 設定にプロダクトIDを保持
		itemCount += getItemCount;
		[[NSUserDefaults standardUserDefaults] setInteger:itemCount
		                                           forKey:@"ConsumableProduct"];
		[[NSUserDefaults standardUserDefaults] synchronize];
        
		[[[UIAlertView alloc] initWithTitle:@"アイテムを取得"
		                            message:[NSString stringWithFormat:@"アイテムをダウンロードしました。アイテムの残数は %ld つです", itemCount]
		                           delegate:nil
		                  cancelButtonTitle:@"OK"
		                  otherButtonTitles:nil] show];
	}
	else {
		[[[UIAlertView alloc] initWithTitle:@"アイテム取得エラー"
		                            message:@"アイテムのダウンロードに失敗しました。リストアしてください。"
		                           delegate:nil
		                  cancelButtonTitle:@"OK"
		                  otherButtonTitles:nil] show];
	}
}

@end
