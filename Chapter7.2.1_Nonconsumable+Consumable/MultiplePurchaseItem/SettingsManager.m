//
//  SettingsManager.m
//  MultiplePurchaseItem
//
//  Created by Tomonori Ohba on 2013/10/31.
//  Copyright (c) 2013年 Purchase and Advertising. All rights reserved.
//

#import "SettingsManager.h"

@implementation SettingsManager

+ (void)saveProductCount:(NSString *)productId count:(int)count {
	// productIdと保有個数をUserDefaultsに保存する
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setInteger:count forKey:productId];
	[userDefaults synchronize];
}

+ (int)getProductCount:(NSString *)productId {
	// productIdの保有個数を返戻する
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	int count = (int)[userDefaults integerForKey:productId];
	return count;
}

@end
