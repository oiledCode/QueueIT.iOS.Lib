#import <UIKit/UIKit.h>

@protocol QueuePassedDelegate;
@protocol QueueViewWillOpenDelegate;
@protocol QueueDisabledDelegate;
@protocol QueueITUnavailableDelegate;
@protocol QueueUserExitedDelegate;

@interface QueueITEngine : NSObject
@property (nonatomic)id<QueuePassedDelegate> queuePassedDelegate;
@property (nonatomic)id<QueueViewWillOpenDelegate> queueViewWillOpenDelegate;
@property (nonatomic)id<QueueDisabledDelegate> queueDisabledDelegate;
@property (nonatomic)id<QueueITUnavailableDelegate> queueITUnavailableDelegate;
@property (nonatomic)id<QueueUserExitedDelegate> queueUserExitedDelegate;
@property (nonatomic, strong)NSString* errorMessage;

typedef enum {
    NetworkUnavailable,
    RequestAlreadyInProgress
} QueueITRuntimeError;
#define QueueITRuntimeErrorArray @"Network connection is unavailable", @"Enqueue request is already in progress", nil

-(instancetype)initWithHost:(UIViewController *)host
                 customerId:(NSString*)customerId
             eventOrAliasId:(NSString*)eventOrAliasId
                 layoutName:(NSString*)layoutName
                   language:(NSString*)language;

-(instancetype)initWithHost:(UIViewController *)host
                 customerId:(NSString *)customerId
             eventOrAliasId:(NSString *)eventOrAliasId
                eventDomain:(NSString *)eventDomain
                  targetURL:(NSString*)targetURL
                    queueId:(NSString *)queueId
                 layoutName:(NSString *)layoutName
                   language:(NSString *)language;

-(void)setViewDelay:(int)delayInterval;
-(void)run;
-(void)raiseQueuePassed;
-(BOOL)isUserInQueue;
-(BOOL)isRequestInProgress;
-(NSString*) errorTypeEnumToString:(QueueITRuntimeError)errorEnumVal;
-(void)raiseUserExited;
-(void)updateQueuePageUrl:(NSString*)queuePageUrl;

+(void)getQueueStatus:(NSString *)customerId
              eventId:(NSString *)eventId
              queueId:(NSString *)queueId
              success:(void(^)(BOOL))success
              failure:(void(^)())failure;
@end

@protocol QueuePassedDelegate <NSObject>
-(void)notifyQueueItTokenReceived:(NSString*)token;
-(void)notifyYourTurn;
@end

@protocol QueueViewWillOpenDelegate <NSObject>
-(void)notifyQueueViewWillOpen;
@optional
-(void)notifyQueueIdReceived:(NSString*)queueId;
@end

@protocol QueueDisabledDelegate <NSObject>
-(void)notifyQueueDisabled;
@end

@protocol QueueITUnavailableDelegate <NSObject>
-(void)notifyQueueITUnavailable: (NSString *) errorMessage;
@end

@protocol QueueUserExitedDelegate <NSObject>
-(void)notifyUserExited;
@end
