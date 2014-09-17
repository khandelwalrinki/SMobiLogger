//
//  SLog.h
//  SMobiLogger
//
//  Created by Systango on 4/12/13.
//  Copyright (c) 2013 Systango. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface SLog : NSManagedObject

@property (nonatomic, retain) NSString *lDescription;
@property (nonatomic, retain) NSDate *lIssueDate;
@property (nonatomic, retain) NSString *lTitle;
@property (nonatomic, retain) NSString *lType;

@end
