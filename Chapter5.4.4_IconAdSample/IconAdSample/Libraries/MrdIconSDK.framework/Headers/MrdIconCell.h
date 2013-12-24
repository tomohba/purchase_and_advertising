/*
 *  MrdIconCell.h
 *  MrdIconSDK
 *
 *  Copyright 2012 marge. All rights reserved.
 *  http://www.astrsk.net/ <support@astrsk.net>
 */

#import <UIKit/UIKit.h>

#define kMrdIconCell_DefaultViewSize (CGSizeMake(75,75))

@class MrdIconLoader;

@interface MrdIconCell : UIView
{}

// Where the icon is to be displayed.
@property (assign, nonatomic) CGRect iconFrame;
// Where the title of app is to be displayed. Set ZeroRect to disable showing.
@property (assign, nonatomic) CGRect titleFrame;

@property (retain, nonatomic) UIFont* titleFont;
@property (retain, nonatomic) UIColor* titleTextColor;
@property (retain, nonatomic) UIColor* titleShadowColor;

// Whether the tap on title string is ignored. Default is NO.
@property (assign, nonatomic) BOOL ignoresTapOnTitle;

- (MrdIconLoader*)loader;

+ (CGFloat)defaultTitleFontSize;
+ (CGRect)defaultTitleFrameForViewSize:(CGSize)viewSize;
+ (CGRect)defaultIconFrameForViewSize:(CGSize)viewSize;

- (BOOL)hasContent;


@end

