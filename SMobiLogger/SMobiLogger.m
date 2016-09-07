//
//  SMobiLogger.m
//  SMobiLogger
//
//  Created by Systango on 4/12/13.
//  Copyright (c) 2013 Systango. All rights reserved.
//

#import "SMobiLogger.h"
#import "SLog.h"
#import "LoggerConstants.h"
#import <MessageUI/MFMailComposeViewController.h>
#include <sys/sysctl.h>

@interface SMobiLogger() <MFMailComposeViewControllerDelegate>
//@interface SMobiLogger()
@property (nonatomic, readonly, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readonly, strong) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, readonly, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController ;
@property (nonatomic, retain) NSTimer* timer;
@property (nonatomic, assign) NSTimeInterval nextUpdateTime;
@property (nonatomic, strong) MFMailComposeViewController *mailViewController;

- (NSURL *)applicationDocumentsDirectory;
- (void)saveLogWithTitle:(NSString *)title description:(NSString *)description logType:(NSString *)logType logDate:(NSDate *)logDate;
- (void)refresh;

- (int)readDateRangeFromPlist;

@end

@implementation SMobiLogger

@synthesize managedObjectContext = _managedObjectContext;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize fetchedResultsController = _fetchedResultsController;
@synthesize timer = _timer;
@synthesize nextUpdateTime = nextUpdateTime_;

+ (SMobiLogger*)sharedInterface {
    static SMobiLogger* singleton = nil;
    
    @synchronized (self) {
        if (!singleton) {
            singleton = [[SMobiLogger alloc] init];
        }
    }
    
    return singleton;
}

#pragma mark init

- (id)init {
    self = [super init];
    convertintoC(self);
    
    if (self) {
        queue_ = dispatch_queue_create("com.Systango.SMobiLogger", NULL);
    }
    
    return self;
}

#pragma mark - Public methods


//Get database filename
+ (NSString *)databaseFilename{
    return @"SMobiLogger.sqlite";
}

//To delete old logs from db
- (void)refreshLogs:(NSNumber*)fromDaysOrNil{
    if(![fromDaysOrNil isKindOfClass:[NSNumber class]])
        fromDaysOrNil = nil;
    
    NSDateFormatter* dateFormat = [[NSDateFormatter alloc] init] ;
    dateFormat.dateStyle = NSDateFormatterShortStyle;
    dateFormat.timeStyle = NSDateFormatterNoStyle;
    NSDate* today = [dateFormat dateFromString:[dateFormat stringFromDate:[NSDate date]]];
    
    
    NSDate *earlierDate = [NSDate dateWithTimeInterval:-(60 * 60 * 24 * (fromDaysOrNil == nil?[self readDateRangeFromPlist]:[fromDaysOrNil intValue])) sinceDate:today];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    //@"SLog"
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"SLog" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    //Setting condition
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(lIssueDate < %@)", earlierDate];
    [fetchRequest setPredicate:predicate];
    
    NSError *error;
    NSArray *items = [_managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    for (NSManagedObject *managedObject in items) {
        [_managedObjectContext deleteObject:managedObject];
    }
    if (![_managedObjectContext save:&error]) {
        NSLog(@"Error deleting Logs- error:%s,%@", __FUNCTION__,error);
    }
    
}

//To Fetch all the logs from db
- (NSString *)fetchLogs{
    NSMutableString *logString = [[NSMutableString alloc] init];
    
    //Get device info
    NSString *systemVersion = [[UIDevice currentDevice] systemVersion];
    
    //Get app version
    NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
    
    [logString appendString:[NSString stringWithFormat:@"Issue raised by %@/%@ with App %@ :-\n", [self deviceName], systemVersion,appVersion]];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"SLog" inManagedObjectContext:self.managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:entity];
    
    NSError *error;
    NSArray *objects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    objects = [[objects reverseObjectEnumerator] allObjects];
    for (SLog *sLog in objects) {
        [logString appendString:[NSString stringWithFormat:@"%@- %@: %@- %@%@", sLog.lIssueDate,sLog.lType, sLog.lTitle, sLog.lDescription, @"\n"]];
    }
    return logString;
}

//To send logs via email
- (void)sendEmailLogs:(id)controller {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.mailViewController = [[MFMailComposeViewController alloc] init];
        self.mailViewController.mailComposeDelegate = (id)self;
        [self.mailViewController setSubject:@"Veromuse:: Support Issue"];
        [self.mailViewController setToRecipients:[NSArray arrayWithObject:@"support@veromuse.com"]];
        [self.mailViewController setMessageBody:@"" isHTML:NO];
        
        NSString *fetchLogString = [self fetchLogs];
        NSData *textFileContentsData = [fetchLogString dataUsingEncoding:NSUTF8StringEncoding];
        
        [self.mailViewController addAttachmentData:textFileContentsData mimeType:@"text/plain" fileName:@"log_file"];
        
        if (controller && self.mailViewController)
        {
            [controller presentViewController:self.mailViewController animated:YES completion:nil];
        }
    });
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.mailViewController dismissViewControllerAnimated:YES completion:nil];
        
        NSString *title = @"Veromuse";
        NSString *message = @"Log report sent successfully.";
        if (error != nil) {
            NSLog(@"Log report sending email fail with error= %@", error);
            return;
        }
        
        if(result == MFMailComposeResultSent)
        {
            [[[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
        }
    });
}

//Save debug logs
- (void)debug:(NSString*)title withDescription:(NSString*)description{
    dispatch_async(queue_, ^{
        [self saveLogWithTitle:title description:description logType:kDebug logDate:[NSDate date]];
    });
}

//Save error logs
- (void)error:(NSString*)title withDescription:(NSString*)description{
    dispatch_async(queue_, ^{
        [self saveLogWithTitle:title description:description logType:kError logDate:[NSDate date]];
    });
}

//Save info logs
- (void)info:(NSString*)title withDescription:(NSString*)description{
    dispatch_async(queue_, ^{
        [self saveLogWithTitle:title description:description logType:kInformation logDate:[NSDate date]];
    });
}

//Save other logs
- (void)other:(NSString*)title withDescription:(NSString*)description{
    dispatch_async(queue_, ^{
        [self saveLogWithTitle:title description:description logType:kOther logDate:[NSDate date]];
    });
}

//Save warnings logs
- (void)warn:(NSString*)title withDescription:(NSString*)description{
    dispatch_async(queue_, ^{
        [self saveLogWithTitle:title description:description logType:kWarning logDate:[NSDate date]];
    });
}

#pragma mark - Private methods

//Get device info
- (NSString *)platform{
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithUTF8String:machine];
    free(machine);
    return platform;
}

- (NSString *) deviceName{
    NSString *platform = [self platform];
    
    if ([platform isEqualToString:@"iPod1,1"])      return @"iPod Touch 1G";
    if ([platform isEqualToString:@"iPod2,1"])      return @"iPod Touch 2G";
    if ([platform isEqualToString:@"iPod3,1"])      return @"iPod Touch 3G";
    if ([platform isEqualToString:@"iPod4,1"])      return @"iPod Touch 4G";
    if ([platform isEqualToString:@"iPod5,1"])      return @"iPod Touch 5G";
    if ([platform isEqualToString:@"iPod7,1"])      return @"iPod Touch 6G";
    
    if ([platform isEqualToString:@"iPad1,1"])      return @"iPad";
    if ([platform isEqualToString:@"iPad2,1"])      return @"iPad 2 (WiFi)";
    if ([platform isEqualToString:@"iPad2,2"])      return @"iPad 2 (GSM)";
    if ([platform isEqualToString:@"iPad2,3"])      return @"iPad 2 (CDMA)";
    if ([platform isEqualToString:@"iPad2,4"])      return @"iPad 2 (WiFi)";
    if ([platform isEqualToString:@"iPad2,5"])      return @"iPad Mini (WiFi)";
    if ([platform isEqualToString:@"iPad2,6"])      return @"iPad Mini (GSM)";
    if ([platform isEqualToString:@"iPad2,7"])      return @"iPad Mini (GSM+CDMA)";
    if ([platform isEqualToString:@"iPad3,1"])      return @"3rd Generation iPad (WiFi)";
    if ([platform isEqualToString:@"iPad3,2"])      return @"3rd Generation iPad (GSM+CDMA)";
    if ([platform isEqualToString:@"iPad3,3"])      return @"3rd Generation iPad (GSM)";
    if ([platform isEqualToString:@"iPad3,4"])      return @"4th Generation iPad (WiFi)";
    if ([platform isEqualToString:@"iPad3,5"])      return @"4th Generation iPad (GSM)";
    if ([platform isEqualToString:@"iPad3,6"])      return @"4th Generation iPad (GSM+CDMA)";
    if ([platform isEqualToString:@"iPad4,1"])      return @"5th Generation iPad (iPad Air) - Wifi";
    if ([platform isEqualToString:@"iPad4,2"])      return @"5th Generation iPad (iPad Air) - Cellular";
    if ([platform isEqualToString:@"iPad4,4"])      return @"2nd Generation iPad Mini - Wifi";
    if ([platform isEqualToString:@"iPad4,5"])      return @"2nd Generation iPad Mini - Cellular";
    if ([platform isEqualToString:@"iPad4,7"])      return @"3rd Generation iPad Mini - Wifi (model A1599)";
    
    if ([platform isEqualToString:@"iPhone1,1"])    return @"iPhone 1G";
    if ([platform isEqualToString:@"iPhone1,2"])    return @"iPhone 3G";
    if ([platform isEqualToString:@"iPhone2,1"])    return @"iPhone 3GS";
    if ([platform isEqualToString:@"iPhone3,1"])    return @"iPhone 4 (GSM)";
    if ([platform isEqualToString:@"iPhone3,3"])    return @"iPhone 4 (CDMA/Verizon/Sprint)";
    if ([platform isEqualToString:@"iPhone4,1"])    return @"iPhone 4S";
    if ([platform isEqualToString:@"iPhone5,1"])    return @"iPhone 5 (GSM)";
    if ([platform isEqualToString:@"iPhone5,2"])    return @"iPhone 5 (GSM+CDMA)";
    if ([platform isEqualToString:@"iPhone5,3"])    return @"iPhone 5c (model A1456, A1532 | GSM)";
    if ([platform isEqualToString:@"iPhone5,4"])    return @"iPhone 5c (model A1507, A1516, A1526 (China), A1529 | Global)";
    if ([platform isEqualToString:@"iPhone6,1"])    return @"iPhone 5s (model A1433, A1533 | GSM)";
    if ([platform isEqualToString:@"iPhone6,2"])    return @"iPhone 5s (model A1457, A1518, A1528 (China), A1530 | Global)";
    if ([platform isEqualToString:@"iPhone7,1"])    return @"iPhone 6 Plus";
    if ([platform isEqualToString:@"iPhone7,2"])    return @"iPhone 6";
    if ([platform isEqualToString:@"iPhone8,1"])    return @"iPhone 6S";
    if ([platform isEqualToString:@"iPhone8,2"])    return @"iPhone 6S Plus";
    if ([platform isEqualToString:@"iPhone8,4"])    return @"iPhone SE";
    
    if ([platform isEqualToString:@"i386"])
        return @"Simulator 32 bit";
    if ([platform isEqualToString:@"x86_64"])
        return @"Simulator 64 bit";
    
    return platform;
}

- (void)scheduleTimer {
    assert([NSThread isMainThread]);
    
    if (self.timer && [self.timer isValid]) {
        [self.timer invalidate];
    }
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:self.nextUpdateTime
                                                  target:self
                                                selector:@selector(refresh)
                                                userInfo:nil
                                                 repeats:NO];
}

- (void)refresh {
    dispatch_async(queue_, ^{
        [self refreshLogs:nil];
    });
    
}

- (void)startMobiLogger{
    [self refresh];
}

//To save logs in db with all required info
- (void)saveLogWithTitle:(NSString *)title description:(NSString *)description logType:(NSString *)logType logDate:(NSDate *)logDate{
    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
    NSEntityDescription *entity = [[self.fetchedResultsController fetchRequest] entity];
    NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:context];
    
    [newManagedObject setValue:title forKey:@"lTitle"];
    [newManagedObject setValue:description forKey:@"lDescription"];
    [newManagedObject setValue:logDate forKey:@"lIssueDate"];
    [newManagedObject setValue:logType forKey:@"lType"];
    
    // Save the context.
    NSError *error = nil;
    if (![context save:&error]) {
        NSLog(@"Unresolved error in MobiLogger %s, %@, %@", __FUNCTION__, error, [error userInfo]);
    }
}

- (int)readDateRangeFromPlist
{
    NSString *bundlePathofPlist = [[NSBundle mainBundle]pathForResource:@"Lib" ofType:@"plist"];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:bundlePathofPlist];
    NSString *dateRange = [dict valueForKey:@"dateRange"];
    return [dateRange intValue];
}

#pragma mark - Core Data stack

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"SLog" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    [fetchRequest setFetchBatchSize:25];
    [fetchRequest setFetchLimit:100];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"lIssueDate" ascending:NO];
    NSArray *sortDescriptors = @[sortDescriptor];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    //aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
    NSError *error = nil;
    if (![self.fetchedResultsController performFetch:&error]) {
        NSLog(@"Unresolved error in MobiLogger %s, %@, %@", __FUNCTION__, error, [error userInfo]);
    }
    
    return self.fetchedResultsController;
}

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"SMobiLogger" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    if (![NSThread currentThread].isMainThread) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            (void)[self persistentStoreCoordinator];
        });
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:[SMobiLogger databaseFilename]];
    NSLog(@"SMobiLogger directory Path: %@", [storeURL path]);
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        /*Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error in MobiLogger %s, %@, %@", __FUNCTION__, error, [error userInfo]);
    }
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL of application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

//#pragma mark - Mail composer delegate method
//- (void)mailComposeController:(MFMailComposeViewController*)controller
//          didFinishWithResult:(MFMailComposeResult)result
//                        error:(NSError*)error;
//{
//    if (result == MFMailComposeResultSent) {
//        NSLog(@"It's away!");
//    }
//    [controller dismissViewControllerAnimated:YES completion:nil];
//}

#pragma mark - Extended log

id object;
id detailDescriptionMessage;

void convertintoC(id self)
{
    object = self;
}

void ExtendNSLog(const char *file, int lineNumber, const char *functionName, NSString *format, ...)
{
    // Type to hold information about variable arguments.
    va_list ap;
    
    // Initialize a variable argument list.
    va_start (ap, format);
    
    // NSLog only adds a newline to the end of the NSLog format if
    // one is not already there.
    // Here we are utilizing this feature of NSLog()
    if (![format hasSuffix: @"\n"])
    {
        format = [format stringByAppendingString: @"\n"];
    }
    //    NSString *body = [[NSString alloc] initWithFormat:format arguments:ap];
    // End using variable argument list.
    va_end (ap);
    
    NSString *fileName = [[NSString stringWithUTF8String:file] lastPathComponent];
    NSString *detailedMessage = [NSString stringWithFormat:@"\n %s Function Name ->(%s) Controller ->(%s:%d) ", getTime(),functionName, [fileName UTF8String],lineNumber];
    detailDescriptionMessage = detailedMessage;
    fprintf(stderr, "%s (%s) (%s:%d) %s", getTime(),
            functionName, [fileName UTF8String],
            lineNumber, [format UTF8String]);
}

char * getTime()
{
    time_t rawtime;
    struct tm * timeinfo;
    char buffer[80];
    
    time (&rawtime);
    timeinfo = localtime (&rawtime);
    
    // see format strings above - YYYY-MM-DD HH:MM:SS
    strftime(buffer, sizeof(buffer), "%F %T", timeinfo);
    
    char *time;
    time=(char *)malloc(64);
    strcpy(time, buffer);
    
    return time;
}

void ExtendNSLogError(const char *file, int lineNumber, const char *functionName, NSString *message, ...)
{
    ExtendNSLog(file, lineNumber, functionName, message);
    [object error:message withDescription:detailDescriptionMessage];
}

void ExtendNSLogWarning(const char *file, int lineNumber, const char *functionName, NSString *message, ...)
{
    ExtendNSLog(file, lineNumber, functionName, message);
    [object warn:message withDescription:detailDescriptionMessage];
}

void ExtendNSLogInfo(const char *file, int lineNumber, const char *functionName, NSString *message, ...)
{
    ExtendNSLog(file, lineNumber, functionName, message);
    [object info:message withDescription:detailDescriptionMessage];
}


@end
