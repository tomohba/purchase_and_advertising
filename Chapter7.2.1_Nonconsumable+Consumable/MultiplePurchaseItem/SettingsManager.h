//
//  SettingsManager.h
//  MultiplePurchaseItem
//
//  Created by Tomonori Ohba on 2013/10/31.
//  Copyright (c) 2013年 Purchase and Advertising. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SettingsManager : NSObject

+ (void)saveProductCount:(NSString*)productId count:(int)count;
+ (int)getProductCount:(NSString*)productId;

@end
