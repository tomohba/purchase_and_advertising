//
//  ReceiptManager.h
//  SinglePurchaseItem
//
//  Created by Tomonori Ohba on 2013/10/29.
//
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@interface ReceiptManager : NSObject

- (int)verifyReceipt:(NSData *)receipt sharedSecret:(NSString *)sharedSecret;

@end
