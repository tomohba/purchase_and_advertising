/*
 *  MrdIconLoader.h
 *  MrdIconSDK
 *
 *  Copyright 2012 marge. All rights reserved.
 *  http://www.astrsk.net/ <support@astrsk.net>
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define kMrd_DEFAULT_REFRESH_INTERVAL 20
#define kMrd_REFRESH_INTERVAL_MIN 10
#define kMrd_REFRESH_INTERVAL_MAX 1500

@class MrdIconCell;
@protocol MrdIconLoaderDelegate;

///////////////////////////////////////////////////////////////////////////

@interface MrdIconLoader : NSObject
{}

// The interval used by the timer refreshes content automatically
// Allowed value range is from kMrd_REFRESH_INTERVAL_MIN to MAX.
@property (nonatomic,assign) NSTimeInterval refreshInterval;

// The delegate object to modify its several behaviors.
// You can pass nil if you do not need any customization.
@property (nonatomic,assign) id<MrdIconLoaderDelegate> delegate;

// The array of MrdIconCell instances already added. 
- (NSArray*)iconCells;

// Add/Remove MrdIconCell. The retain-count of added cell is to be incremented.
- (void)addIconCell:(MrdIconCell*)iconCell;
- (void)removeIconCell:(MrdIconCell*)iconCell;


//  Start retrieving advertisement content.
- (void)startLoadWithMediaCode:(NSString*)mediaCode ;

// Stop retrieving and delete content of banner.
// If called when already stopped, the receiver simply ignores calling.
- (void)stop;

// Force to refresh content.
- (void)refresh;

// The media code currently used. Returns nil when not started. 
- (NSString*)mediaCode;

@end

///////////////////////////////////////////////////////////////////////////

@protocol MrdIconLoaderDelegate <NSObject>

// Called after the loader changes cells with valid contents.
- (void)loader:(MrdIconLoader*)loader didReceiveContentForCells:(NSArray*)cells;

// Called when the loader failed to get contents for cells.
// This may be called after -loader:didReceiveContentForCells: when 
//  found contents is less than count of added cells.  
- (void)loader:(MrdIconLoader*)loader didFailToLoadContentForCells:(NSArray*)cells;

// Called as soon as the view was tapped.
// You can prevent opening browser with returning NO.
// Also you might do something before your app will be suspended.
// (e.g.; pause game, save user`s data, logging, etc.) 
// When YES is returned or delegate does not implement this, the app will open url.
- (BOOL)loader:(MrdIconLoader*)loader willHandleTapOnCell:(MrdIconCell*)aCell;

// Called before app will open url
- (void)loader:(MrdIconLoader*)loader willOpenURL:(NSURL*)url cell:(MrdIconCell*)aCell;

@end

