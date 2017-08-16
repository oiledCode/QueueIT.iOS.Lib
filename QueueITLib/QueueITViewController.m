#import "QueueITViewController.h"
#import "QueueITEngine.h"

@interface QueueITViewController ()<UIWebViewDelegate, NSURLConnectionDelegate>

@property (nonatomic) UIWebView* webView;
@property (nonatomic, strong) UIViewController* host;
@property (nonatomic, strong) QueueITEngine* engine;
@property (nonatomic, strong) NSString* queueUrl;
@property (nonatomic, strong) NSString* eventTargetUrl;
@property (nonatomic, strong) UIActivityIndicatorView* spinner;
@property (nonatomic, strong) NSString* customerId;
@property (nonatomic, strong) NSString* eventId;
@property (nonatomic, strong) NSURLRequest *firstRequest;
@property BOOL authenticated;
@property BOOL isQueuePassed;

@end

static NSString * const JAVASCRIPT_GET_BODY_CLASSES = @"document.getElementsByTagName(\"body\")[0].className";

@implementation QueueITViewController

-(instancetype)initWithHost:(UIViewController *)host
                queueEngine:(QueueITEngine*) engine
                   queueUrl:(NSString*)queueUrl
             eventTargetUrl:(NSString*)eventTargetUrl
                 customerId:(NSString*)customerId
                    eventId:(NSString*)eventId
{
    self = [super init];
    if(self) {
        self.host = host;
        self.engine = engine;
        self.queueUrl = queueUrl;
        self.eventTargetUrl = eventTargetUrl;
        self.customerId = customerId;
        self.eventId = eventId;
        self.isQueuePassed = NO;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.authenticated = false;
}

-(void)viewWillAppear:(BOOL)animated{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    self.spinner = [[UIActivityIndicatorView alloc]initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
    [self.spinner setColor:[UIColor grayColor]];
    [self.spinner startAnimating];
    
    CGSize size = self.view.bounds.size;
    
    UIView *topBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width, 64.0)];
    [topBar setBackgroundColor:[UIColor whiteColor]];
    UIView *topBarSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 63, size.width, 1)];
    topBarSeparator.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.2];
    [topBar addSubview:topBarSeparator];
    
    UIButton *closeButton = [[UIButton alloc] initWithFrame:CGRectMake(size.width - 100, 20, 100, 44.0)];
    [closeButton setTitle:@"close" forState:UIControlStateNormal];
    [closeButton setTitleColor:[UIColor colorWithRed:235.0/255.0 green:0 blue:139.0/255.0 alpha:1.0] forState:UIControlStateNormal];
    [closeButton addTarget:self action:NSSelectorFromString(@"dismissController") forControlEvents:UIControlEventTouchUpInside];
    [topBar addSubview:closeButton];
    [self.view addSubview:topBar];
    
    self.webView = [[UIWebView alloc]initWithFrame:CGRectMake(0, 64.0, size.width, size.height - 64.0)];
    [self.view addSubview:self.webView];
    [self.webView addSubview:self.spinner];
    
    NSURL *urlAddress = [NSURL URLWithString:self.queueUrl];
    NSURLRequest *request = [NSURLRequest requestWithURL:urlAddress];
    [self.webView loadRequest:request];
    self.webView.delegate = self;
}


- (void)dismissController {
    [self.host dismissViewControllerAnimated:YES completion:^{
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    }];
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView
    shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if (!self.authenticated) {
        self.firstRequest = request;
        NSURLConnection * connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        [connection start];
        return NO;
    }
    if (!self.isQueuePassed) {
        NSString* urlString = [[request URL] absoluteString];
        NSString* targetUrlString = self.eventTargetUrl;
        
        if (urlString != nil) {
            NSURL* url = [NSURL URLWithString:urlString];
            NSURL* targetUrl = [NSURL URLWithString:targetUrlString];
            if(urlString != nil && ![urlString isEqualToString:@"about:blank"]) {
                BOOL isQueueUrl = [self.queueUrl containsString:url.host];
                BOOL isFrame = ![[[request URL] absoluteString] isEqualToString:[[request mainDocumentURL] absoluteString]];
                if (!isFrame) {
                    if (isQueueUrl) {
                        [self.engine updateQueuePageUrl:urlString];
                    }
                    if ([targetUrl.host containsString:url.host]) {
                        self.isQueuePassed = YES;
                        
                        [self.engine.queuePassedDelegate notifyQueueItTokenReceived:[self queueItTokenWithURL:[request URL]]];
                        [self.engine raiseQueuePassed];
                        [self.host dismissViewControllerAnimated:YES completion:^{
                            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                        }];
                    } else if (navigationType == UIWebViewNavigationTypeLinkClicked && !isQueueUrl) {
                        [[UIApplication sharedApplication] openURL:[request URL]];
                        return NO;
                    }
                }
            }
        }
    }
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    [self.spinner stopAnimating];
    if (![self.webView isLoading])
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    }

    // Check if user exitted through the default exit link and notify the engine
    NSArray<NSString *> *htmlBodyClasses = [[self.webView stringByEvaluatingJavaScriptFromString:JAVASCRIPT_GET_BODY_CLASSES] componentsSeparatedByString:@" "];
    BOOL isExitClassPresent = [htmlBodyClasses containsObject:@"exit"];
    if (isExitClassPresent) {
        [self.engine raiseUserExited];
    }
}

-(void)appWillResignActive:(NSNotification*)note
{
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    [self.host dismissViewControllerAnimated:YES completion:^{
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    }];
}

-(NSString*)queueItTokenWithURL:(NSURL*)url {
    NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:false];
    NSArray *queryItems = urlComponents.queryItems;
    for (NSURLQueryItem *item in queryItems) {
        if ([item.name isEqualToString:@"queueittoken"]) {
            return item.value;
        }
    }
    return NULL;
}

#pragma MARK -  NSURLConnectionDelegate
-(void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
            [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
    }
    [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
}
-(void)connection:(NSURLConnection*)connection didReceiveResponse:(nonnull NSURLResponse *)response {
    self.authenticated = YES;
    [connection cancel];
    [self.webView loadRequest:self.firstRequest];
    
}
@end
