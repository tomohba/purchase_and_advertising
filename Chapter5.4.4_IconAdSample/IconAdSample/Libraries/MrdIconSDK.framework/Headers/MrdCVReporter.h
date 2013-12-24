/*
 *  MrdCVReporter.h
 *  MrdIconSDK
 *
 *  Copyright 2012 marge. All rights reserved.
 *  http://www.astrsk.net/ <support@astrsk.net>
 */


#import <Foundation/Foundation.h>

#define kMrdDEFAULTS_KEY_BLOCK_SENDING_CV @"net.astrsk.BlockSendingCV"


@interface MrdCVReporter : NSObject

+ (BOOL)sendUntilSuccess:(NSString*)promotionKey retryInterval:(NSTimeInterval)sec;

@end


//////////////////////////////////////////////////////////////////////////////////

// When you need to control more, please use APIs below.

// This is a summary of the implemention in sendUntilSuccess:retryInterval ;
/*
- (void)sendConversion
{
	NSLog(@"Now start sending conversion ...");
  NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	if ([ud objectForKey:kMrdDEFAULTS_KEY_BLOCK_SENDING_CV])
	{
		NSLog(@"CV Report has already been sent. We do nothing.");
		return;
	}
	MrdCVReporter* reporter;
	reporter = [MrdCVReporter reporterWithPromotionKey:kPROMOTION_KEY];
	[reporter sendWithDelegate:self];
}

- (void)cvReporterDidSucceed:(MrdCVReporter*)reporter
{
	NSLog(@"Sending conversion succeeded.");
  // Save the key to prevent sending on next launching
  NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setObject:@"YES" forKey:kMrdDEFAULTS_KEY_BLOCK_SENDING_CV];
}

- (void)cvReporter:(MrdCVReporter*)reporter didFailWithError:(NSError*)error
{
	if ([[error domain]isEqualToString:NSURLErrorDomain])
	{
		[self performSelector:@selector(sendConversion) withObject:nil afterDelay:20];
		NSLog(@" Sending CV failed (%@;%d), Retry after 20 seconds delay.", [error domain], [error code]);
		
		return;
	}
	NSLog(@" Sending CV failed (%@;%d)", [error domain], [error code]);
}
*/

// Status
typedef enum {
	MrdCVReporterStatus_UNDEF   =  0, // No changes after init.
	MrdCVReporterStatus_SENDING =  1, 
	MrdCVReporterStatus_SUCCESS =  2,
	MrdCVReporterStatus_NO_DATA =  3, // Device has no data should be sent
	MrdCVReporterStatus_ERROR   = -1,
} MrdCVReporterStatus;

// Error codes
enum {
	MrdCVReporterError_NoError          = 0,
	MrdCVReporterError_NotFound         = 1, // Saved PR/User pair was not found on server
	MrdCVReporterError_PromotionClosed  = 2,
	MrdCVReporterError_ReportDuplicated = 3,
	MrdCVReporterError_InvalidFormat    = 4, // HTTP Request param/header is corrupted
};

extern NSString* MrdCVReporterErrorDomain;

@protocol MrdCVReporterDelegate;


@interface MrdCVReporter(DetailedManipuration)

+ (id)reporterWithPromotionKey:(NSString*)promotionKey;

// start sending. returns YES if successfully started .
- (BOOL)sendWithDelegate:(id<MrdCVReporterDelegate>)delegate;

- (NSString*)promotionKey;

- (MrdCVReporterStatus)status;

@end

@protocol MrdCVReporterDelegate<NSObject>

@optional
- (void)cvReporterDidSucceed:(MrdCVReporter*)reporter;
- (void)cvReporter:(MrdCVReporter*)reporter didFailWithError:(NSError*)error;

@end

