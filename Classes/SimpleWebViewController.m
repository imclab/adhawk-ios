//
//  SimpleWebViewController.m
//  adhawk
//
//  Created by Daniel Cloud on 7/27/12.
//  Copyright (c) 2012 Sunlight Foundation. All rights reserved.
//

#import "SimpleWebViewController.h"
#import "Settings.h"
#import <UIWebView+AFNetworking.h>
#import <UIAlertView+AFNetworking.h>

@interface SimpleWebViewController ()

- (void)loadTargetURL;

@end

@implementation SimpleWebViewController
{
    BOOL _targetURLLoaded;
}

@synthesize webView;
@synthesize activityIndicator;
@synthesize targetURL;
@synthesize loadTargetURLonViewWillAppear;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];

    if (self) {
        self.loadTargetURLonViewWillAppear = YES;
        _targetURLLoaded = NO;
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.webView.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (self.loadTargetURLonViewWillAppear && !_targetURLLoaded) {
        [self loadTargetURL];
    }
}

#pragma mark - SimpleWebViewController methods

- (void)setAndLoadTargetURL:(NSURL *)url
{
    self.targetURL = url;
    [self loadTargetURL];
}

#pragma mark - UIWebViewDelegate methods

- (BOOL)webView:(UIWebView *)p_webView shouldStartLoadWithRequest:(NSURLRequest *)p_request navigationType:(UIWebViewNavigationType)navigationType
{
    self.targetURL = (self.targetURL != [p_request URL]) ? [p_request URL] : self.targetURL;

//    Check headers for custom x-header
    NSMutableURLRequest *customRequest = [p_request copy];
    
    BOOL needRequestOverride = [[p_request allHTTPHeaderFields] objectForKey:@"X-Client-App"] == nil ? YES : NO;
    
    if (needRequestOverride) {
        NSLog(@"Overriding headers");
        [customRequest addValue:kClientAppHeader forHTTPHeaderField:@"X-Client-App"];
        [p_webView loadRequest:customRequest];

        return NO;
    }
    
    return YES;
}

- (void)webView:(UIWebView *)p_webView didFailLoadWithError:(NSError *)error
{
    NSLog(@"error: %@", [error localizedDescription]);
    [self.activityIndicator stopAnimating];
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [self.activityIndicator startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSLog(@"webViewDidFinishLoad");
    [self.activityIndicator stopAnimating];
}

#pragma mark - Private

- (void)loadTargetURL
{
    if (self.targetURL && ![[self.targetURL absoluteString] isEqualToString: @""]) {
        NSLog(@"Requesting: %@", [self.targetURL absoluteString]);
        NSURLRequest *req = [NSURLRequest requestWithURL:self.targetURL];

        [self.activityIndicator startAnimating];
        __weak SimpleWebViewController *weakSelf = self;
        [self.webView loadRequest:req progress:nil
              success:^NSString *(NSHTTPURLResponse *response, NSString *HTML) {
                  [weakSelf.activityIndicator stopAnimating];
                  _targetURLLoaded = YES;

                  return HTML;
              } failure:^(NSError *error) {
                  [weakSelf.activityIndicator stopAnimating];
              }];

#if TESTFLIGHT
        if (TESTING == YES) [TestFlight passCheckpoint:@"Requested Ad detail page"];
#endif
    }
}

@end
