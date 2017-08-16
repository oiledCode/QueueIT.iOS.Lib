#import "QueueService.h"
#import "QueueService_NSURLConnection.h"

static QueueService *SharedInstance;

static NSString * const API_ROOT = @"http://%@.queue-it.net/api/queue";

@implementation QueueService

+ (QueueService *)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SharedInstance = [[QueueService_NSURLConnection alloc] init];
    });
    
    return SharedInstance;
}

-(NSString*)enqueue:(NSString *)customerId
     eventOrAliasId:(NSString *)eventorAliasId
             userId:(NSString *)userId
          userAgent:(NSString *)userAgent
         sdkVersion:(NSString*)sdkVersion
         layoutName:(NSString*)layoutName
           language:(NSString*)language
            success:(void (^)(QueueStatus *))success
            failure:(QueueServiceFailure)failure
{
    NSDictionary* bodyDict = nil;
    if (layoutName && language) {
        bodyDict = @{ @"userId": userId, @"userAgent": userAgent, @"sdkVersion":sdkVersion, @"layoutName":layoutName, @"language":language };
    }else if(layoutName && !language) {
        bodyDict = @{ @"userId": userId, @"userAgent": userAgent, @"sdkVersion":sdkVersion, @"layoutName":layoutName };
    }else if(!layoutName && language) {
        bodyDict = @{ @"userId": userId, @"userAgent": userAgent, @"sdkVersion":sdkVersion, @"language":language };
    }else {
        bodyDict = @{ @"userId": userId, @"userAgent": userAgent, @"sdkVersion":sdkVersion };
    }
    
    NSString* urlAsString = [NSString stringWithFormat:API_ROOT, customerId];
    urlAsString = [urlAsString stringByAppendingString:[NSString stringWithFormat:@"/%@", customerId]];
    urlAsString = [urlAsString stringByAppendingString:[NSString stringWithFormat:@"/%@", eventorAliasId]];
    urlAsString = [urlAsString stringByAppendingString:[NSString stringWithFormat:@"/appenqueue"]];
    
    return [self submitPUTPath:urlAsString body:bodyDict
            success:^(NSData *data)
            {
                NSError *error = nil;
                NSDictionary *userDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                if (userDict && [userDict isKindOfClass:[NSDictionary class]])
                {
                    QueueStatus* queueStatus = [[QueueStatus alloc] initWithDictionary:userDict];
                    
                    if (success != NULL) {
                        success(queueStatus);
                    }
                } else if (success != NULL) {
                    success(NULL);
                }
            }
            failure:^(NSError *error, NSString* errorMessage)
            {
                failure(error, errorMessage);
            }];
}

-(void)getQueueStatus:(NSString *)customerId
              eventId:(NSString *)eventId
              queueId:(NSString *)queueId
              success:(void (^)(BOOL))success
              failure:(void (^)())failure {
    NSString * urlString = [NSString stringWithFormat:@"http://%@.queue-it.net/api/nativeapp/qoqa/%@/queue/%@/status", customerId, eventId, queueId];
    NSDictionary *body = @{@"configId" : @"not-used", @"widgets": @[]};
    [self submitPUTPath:urlString body:body
                       success:^(NSData *data)
            {
                NSError *error = nil;
                NSDictionary *userDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                if (userDict && [userDict isKindOfClass:[NSDictionary class]])
                {
                    if (userDict[@"rejectDetails"] != nil) {
                        success(false);
                    } else {
                        success(true);
                    }
                } else {
                    success(false);
                }
            }
            failure:^(NSError *error, NSString* errorMessage)
            {
                failure();
            }];
}

- (NSString *)submitPUTPath:(NSString *)path
                       body:(NSDictionary *)bodyDict
                    success:(QueueServiceSuccess)success
                    failure:(QueueServiceFailure)failure
{
    NSURL *url = [NSURL URLWithString:path];
    return [self submitRequestWithURL:url
                               method:@"PUT"
                                 body:bodyDict
                       expectedStatus:200
                              success:success
                              failure:failure];
}


#pragma mark - Abstract methods
- (NSString *)submitRequestWithURL:(NSURL *)URL
                            method:(NSString *)httpMethod
                              body:(NSDictionary *)bodyDict
                    expectedStatus:(NSInteger)expectedStatus
                           success:(QueueServiceSuccess)success
                           failure:(QueueServiceFailure)failure
{
    return nil;
}


@end
