//
//  SMobiLogger.h
//  SMobiLogger
//
//  Created by Systango on 4/12/13.
//  Copyright (c) 2013 Systango. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SMobiLogger : NSObject {
	dispatch_queue_t queue_;
}
// To create a sigelton object
+ (SMobiLogger *)sharedInterface;

// Get database filename
+ (NSString *)databaseFilename;

// To delete old logs from db
- (void)refreshLogs:(NSNumber *)fromDaysOrNil;

// To Fetch all the logs from db
- (NSString *)fetchLogs;

// To send logs via email
- (void)sendEmailLogs:(id)controller;

// Save logs with particulare type
- (void)debug:(NSString *)title withDescription:(NSString *)description;
- (void)error:(NSString *)title withDescription:(NSString *)description;
- (void)info:(NSString *)title withDescription:(NSString *)description;
- (void)other:(NSString *)title withDescription:(NSString *)description;
- (void)warn:(NSString *)title withDescription:(NSString *)description;

// To start timer, which delete old logs
- (void)startMobiLogger;



@end