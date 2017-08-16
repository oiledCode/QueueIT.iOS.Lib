#import <Foundation/Foundation.h>
#import "QueueStatus.h"

typedef void (^QueueServiceSuccess)(NSData *data);
typedef void (^QueueServiceFailure)(NSError *error, NSString* errorMessage);

@interface QueueService : NSObject
+ (QueueService *)sharedInstance;

-(NSString*)enqueue:(NSString*)customerId
     eventOrAliasId:(NSString*)eventorAliasId
             userId:(NSString*)userId
          userAgent:(NSString*)userAgent
         sdkVersion:(NSString*)sdkVersion
         layoutName:(NSString*)layoutName
           language:(NSString*)language
            success:(void(^)(QueueStatus* queueStatus))success
            failure:(QueueServiceFailure)failure;

-(void)getStatus:(NSString*)customerId eventId:(NSString*)eventId queueId:(NSString*)queueId configId:(NSString*)configId;


@end
