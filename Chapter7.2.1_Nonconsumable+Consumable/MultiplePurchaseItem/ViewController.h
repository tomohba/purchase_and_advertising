//
//  ViewController.h
//  MultiplePurchaseItem
//
//  Created by Tomonori Ohba on 2013/10/31.
//  Copyright (c) 2013年 Purchase and Advertising. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>

@interface ViewController : UIViewController <SKProductsRequestDelegate>
{
    SKProductsRequest *myProductRequest; // プロダクト取得用
    NSMutableArray *myProducts;          // 取得したプロダクト情報を保持する配列
}

@property (weak, nonatomic) IBOutlet UITableView *productTable;
@property (weak, nonatomic) IBOutlet UITableView *itemTable;
- (IBAction)restoreButtonOnTouch:(id)sender;

@end
