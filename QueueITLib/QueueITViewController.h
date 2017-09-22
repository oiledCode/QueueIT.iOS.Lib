#import <UIKit/UIKit.h>
#import "QueueITEngine.h"

@interface QueueITViewController : UIViewController

@property (nonatomic, strong) UIImage *closeImage;

-(instancetype)initWithHost:(UIViewController *)host
                queueEngine:(QueueITEngine*) engine
                   queueUrl:(NSString*)queueUrl
             eventTargetUrl:(NSString*)eventTargetUrl
                 customerId:(NSString*)customerId
                    eventId:(NSString*)eventId;

@end

