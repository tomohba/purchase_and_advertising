//
//  ReceiptManager.m
//  SinglePurchaseItem
//
//  Created by Tomonori Ohba on 2013/10/29.
//
//

#import "ReceiptManager.h"

@implementation ReceiptManager

- (int)verifyReceipt:(NSData *)receipt sharedSecret:(NSString *)sharedSecret {
	// iTunes Store
	NSDictionary *dict = [self verifyReceipt:receipt password:sharedSecret];
	int status = [self savePurchaseInfo:dict];
	return status;
}

- (NSDictionary *)verifyReceipt:(NSData *)receipt password:(NSString *)password {
	// レシート確認用のJSON送信データを生成
	NSString *receiptStr = [[NSString alloc] initWithData:receipt encoding:NSUTF8StringEncoding];
	NSString *receiptJson = [NSString stringWithFormat:@"{\"receipt-data\":\"%@\", \"password\":\"%@\"}",
	                         receiptStr, password];
    
	// 本環境のiTunes Storeへレシートを確認
	NSDictionary *dict = [self verifyReceiptToITS:@"https://buy.itunes.apple.com/verifyReceipt"
	                                  receiptJson:receiptJson];
    
	// status code 21007ならSandbox環境のレシートなので、Sandbox環境でレシートを確認する
	NSNumber *status = [dict objectForKey:@"status"];
	if ([status intValue] == 21007) {
		dict = [self verifyReceiptToITS:@"https://sandbox.itunes.apple.com/verifyReceipt"
		                    receiptJson:receiptJson];
	}
    
	return dict;
}

- (NSDictionary *)verifyReceiptToITS:(NSString *)urlString receiptJson:(NSString *)receiptJson {
	// iTunes Storeへレシート確認リクエストを送信する
	NSURL *url = [NSURL URLWithString:urlString];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
	[request setHTTPBody:[receiptJson dataUsingEncoding:NSUTF8StringEncoding]];
	[request setHTTPMethod:@"POST"];
    
	NSError *error;
	NSURLResponse *response;
	// 同期的HTTP通信
	NSData *decodeData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
	// 応答からJSONを生成
	NSString *receipt = [[NSString alloc] initWithData:decodeData encoding:NSUTF8StringEncoding];
	NSData *jsonData = [receipt dataUsingEncoding:NSUnicodeStringEncoding];
    
	// JSON を NSDictionary に変換する
	NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData
	                                                     options:NSJSONReadingAllowFragments
	                                                       error:&error];
	return dict;
}

- (int)savePurchaseInfo:(NSDictionary *)dict {
	// レシートのstatusを確認する
	int status = [[dict objectForKey:@"status"] intValue];
    
	// statusが0でなければ、有効でないレシート
	if (status != 0) {
		NSLog(@"status: %d", status);
		return status;
	}
    
	if ([[dict allKeys]containsObject:@"environment"] == YES) { // 新型レシート
		// latest_receipt_info配列をまわして、最大の有効期限値を取得する
		NSArray *receiptArray = [dict objectForKey:@"latest_receipt_info"];
		NSNumber *expiresDateMax = [[NSNumber alloc] init];
		for (NSDictionary *receiptDict in receiptArray) {
			NSNumber *expiresDate = [receiptDict objectForKey:@"expires_date_ms"];
			if ([expiresDateMax doubleValue] < [expiresDate doubleValue]) {
				expiresDateMax = expiresDate;
			}
		}
        
		// 有効期限が切れていないか判定する
		NSTimeInterval expires = [expiresDateMax doubleValue] / 1000.0;
		if (expires < [[NSDate date] timeIntervalSince1970]) {
			NSLog(@"status: 21006 (expired manualy)");
			return 21006;
		}
        
		NSString *latestReceipt = [dict objectForKey:@"latest_receipt"];
		// UserDefaultに保存する
		[[NSUserDefaults standardUserDefaults] setObject:expiresDateMax
		                                          forKey:@"expires_date"];
		[[NSUserDefaults standardUserDefaults] setValue:latestReceipt
		                                         forKey:@"latest_receipt"];
		[[NSUserDefaults standardUserDefaults] synchronize];
        
		NSLog(@"status: 0");
		return 0;
	}
	else { // 旧型レシート
        // 有効期限と最も最近のレシートを取得
		NSDictionary *receiptDict = [dict objectForKey:@"latest_receipt_info"];
		NSNumber *expiresDate = [receiptDict objectForKey:@"expires_date"]; // UNIX時間（1970年からの経過ミリ秒）
		NSString *latestReceipt = [dict objectForKey:@"latest_receipt"];
        
		// UNIX時間からNSDateへ変換
		NSTimeInterval expires = [expiresDate doubleValue] / 1000.0;
        
		// リストアのときは、statusが0でも現在時刻より過去の日付が返ってくることがあるので
		// 現在時刻と比較し、過去の日付であれば有効期限切れと同じstatus値を返戻する
		if (expires < [[NSDate date] timeIntervalSince1970]) {
			NSLog(@"status: 21006 (expired manualy)");
			return 21006;
		}
        
		// UserDefaultに保存する
		[[NSUserDefaults standardUserDefaults] setObject:expiresDate
		                                          forKey:@"expires_date"];
		[[NSUserDefaults standardUserDefaults] setValue:latestReceipt
		                                         forKey:@"latest_receipt"];
		[[NSUserDefaults standardUserDefaults] synchronize];
        
		NSLog(@"status: 0");
		return 0;
	}
}

@end
