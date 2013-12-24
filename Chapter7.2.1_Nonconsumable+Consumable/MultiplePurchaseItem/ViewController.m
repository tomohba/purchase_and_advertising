//
//  ViewController.m
//  MultiplePurchaseItem
//
//  Created by Tomonori Ohba on 2013/10/31.
//  Copyright (c) 2013年 Purchase and Advertising. All rights reserved.
//

#import "ViewController.h"
#import "ProductIds.h"
#import "SettingsManager.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];
    
	// 複数のプロダクト情報を取得する
	NSSet *productIdentifiers = [NSSet setWithObjects:PRODCUCTID_PORTION, PRODCUCTID_BOOMELANG, nil];
	myProducts = nil;
	myProductRequest = [[SKProductsRequest alloc]
	                    initWithProductIdentifiers:productIdentifiers];
	myProductRequest.delegate = self;
	[myProductRequest start];
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
	                                         selector:@selector(restored:)
	                                             name:@"Restored"
	                                           object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
	                                         selector:@selector(failed:)
	                                             name:@"Failed"
	                                           object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
    
	// AppDelegateからの、購入通知を解除する
	[[NSNotificationCenter defaultCenter] removeObserver:self
	                                                name:@"Purchased"
	                                              object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self
	                                                name:@"Restored"
	                                              object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self
	                                                name:@"Failed"
	                                              object:nil];
}

// SKProductsRequestDelegate
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
	// プロダクトが取得できなかった
	if (response == nil) {
		NSString *message = @"プロダクトが取得できませんでした";
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"エラー"
		                                                message:message
		                                               delegate:nil
		                                      cancelButtonTitle:@"OK"
		                                      otherButtonTitles:nil];
		[alert show];
		return;
	}
    
	// 確認できなかったidentifierをログに記録
	for (NSString *identifier in response.invalidProductIdentifiers) {
		NSLog(@"invalidProductIdentifiers: %@", identifier);
	}
    
	// アプリ内課金プロダクトを取得
	myProducts = [NSMutableArray arrayWithArray:response.products];
    
	// 商品情報が1つも取得できなかった
	if (myProducts == nil || myProducts.count == 0) {
		NSString *message = @"プロダクトが取得できませんでした";
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"エラー"
		                                                message:message
		                                               delegate:nil
		                                      cancelButtonTitle:@"OK"
		                                      otherButtonTitles:nil];
		[alert show];
		return;
	}
    
	// 販売中アイテム、購入済みアイテムテーブルの内容を更新する
	[self.productTable reloadData];
	[self.itemTable reloadData];
}

- (IBAction)restoreButtonOnTouch:(id)sender {
	// リストア要求
	[[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	// セクション数は1
	return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	// セクション文字は返さない
	return @"";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	// 取得したアイテムの数だけ表示したい、商品情報配列の要素数を返戻する
	return myProducts == nil ? 0 : myProducts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (tableView == self.productTable) {
		return [self setProductCell:tableView cellForRowAtIndexPath:indexPath];
	}
	else if (tableView == self.itemTable) {
		return [self setItemCell:tableView cellForRowAtIndexPath:indexPath];
	}
	else {
		return nil;
	}
}

- (UITableViewCell *)setProductCell:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	// プロダクト情報を配列から取得
	SKProduct *myProduct = myProducts[indexPath.row];
    
	// ローカライズ後の価格を取得
	NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
	[numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
	[numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
	[numberFormatter setLocale:myProduct.priceLocale];
	NSString *localedPrice = [numberFormatter stringFromNumber:myProduct.price];
    
	// TableCell内のUILabelを取得
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TableViewCell"];
	UILabel *label1 = (UILabel *)[cell viewWithTag:1]; // 商品名
	UILabel *label2 = (UILabel *)[cell viewWithTag:2]; // 商品情報詳細
	UILabel *label3 = (UILabel *)[cell viewWithTag:3]; // 販売価格
    
	// 商品情報を表示
	label1.text = myProduct.localizedTitle;           // 商品名
	label2.text = myProduct.localizedDescription;     // 商品情報詳細
	label3.text = localedPrice;                       // 販売価格
    
	return cell;
}

- (UITableViewCell *)setItemCell:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	// プロダクト情報を配列から取得
	SKProduct *myProduct = myProducts[indexPath.row];
    
	// アプリ設定から、Productの保有個数を取得
	int count = [SettingsManager getProductCount:myProduct.productIdentifier];
    
	// TableCell内のUILabelを取得
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TableViewCell"];
	UILabel *label1 = (UILabel *)[cell viewWithTag:1]; // 商品名
	UILabel *label2 = (UILabel *)[cell viewWithTag:2]; // 保持数
    
	// 商品情報を表示
	label1.text = myProduct.localizedTitle;                   // 商品名
	label2.text = [NSString stringWithFormat:@"%d個", count]; // 商品情報詳細
    
	return cell;
}

// Table Rowのタッチ処理
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (tableView == self.productTable) {
		[self purchaseItem:indexPath];
	}
	else if (tableView == self.itemTable) {
		[self useItem:indexPath];
	}
}

- (void)purchaseItem:(NSIndexPath *)indexPath {
	// 機能制限 - App内の購入　のチェックを行う
	if ([SKPaymentQueue canMakePayments] == NO) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Message"
		                                                message:@"アプリ内課金が制限されているため購入できませんでした."
		                                               delegate:nil
		                                      cancelButtonTitle:@"OK"
		                                      otherButtonTitles:nil];
		[alert show];
		return;
	}
    
	// プロダクト情報を取得
	SKProduct *myProduct = myProducts[indexPath.row];
    
	// 購入処理を開始する
	SKPayment *payment = [SKPayment paymentWithProduct:myProduct];
    
	// SKPaymentQueueに追加＝トランザクションが開始される
	[[SKPaymentQueue defaultQueue] addPayment:payment];
}

- (void)useItem:(NSIndexPath *)indexPath {
	// 課金プロダクトを取得
	SKProduct *myProduct = myProducts[indexPath.row];
	NSString *productId = myProduct.productIdentifier;
	NSString *productName = myProduct.localizedTitle;
    
	// ポーションは消耗型アイテムなので、保持数を減算する
	if ([productId isEqualToString:PRODCUCTID_PORTION] == YES) {
		// 現在の保持数を取得
		int count = [SettingsManager getProductCount:productId];
        
		// 0個なら消耗できない
		if (count == 0) {
			NSString *message = @"0個だよ！使う前に購入してね！";
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Message"
			                                                message:message
			                                               delegate:nil
			                                      cancelButtonTitle:@"OK"
			                                      otherButtonTitles:nil];
			[alert show];
			return;
		}
        
		// 消耗処理を行う
		count--;
		[SettingsManager saveProductCount:productId count:count];
        
		NSString *message = [NSString stringWithFormat:@"%@を使った！ライフが回復！", productName];
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Message"
		                                                message:message
		                                               delegate:nil
		                                      cancelButtonTitle:@"OK"
		                                      otherButtonTitles:nil];
		[alert show];
        
		// 購入済みテーブルをリロードして表示を更新
		[self.itemTable reloadData];
	}
	// ブーメランは非消耗型アイテムなので減算しない
	if ([productId isEqualToString:PRODCUCTID_BOOMELANG] == YES) {
		// 現在の保持数を取得
		int count = [SettingsManager getProductCount:productId];
        
		// 0個とそれ以外でメッセージを変える
		NSString *message = count == 0 ?
        @"0個だよ！使う前に購入してね！" :
        [NSString stringWithFormat:@"%@を使った！だが何も起こらなかった...", productName];
        
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Message"
		                                                message:message
		                                               delegate:nil
		                                      cancelButtonTitle:@"OK"
		                                      otherButtonTitles:nil];
		[alert show];
	}
}

- (void)purchased:(NSNotification *)notification {
	// 購入済みテーブルをリロードして表示を更新
	[self.itemTable reloadData];
    
	// notification.objectはSKPaymentTransactionである
	SKPaymentTransaction *transaction = (SKPaymentTransaction *)notification.object;
    
	// 購入後の保持数を表示する
	NSString *productId = transaction.payment.productIdentifier;
	int count = [SettingsManager getProductCount:productId];
	NSString *message = [NSString stringWithFormat:@"購入完了！ %d 個になりました.", count];
    
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Message"
	                                                message:message
	                                               delegate:nil
	                                      cancelButtonTitle:@"OK"
	                                      otherButtonTitles:nil];
	[alert show];
}

- (void)restored:(NSNotification *)notification {
	// 購入済みテーブルをリロードして表示を更新
	[self.itemTable reloadData];
}

- (void)failed:(NSNotification *)notification {
}

@end
