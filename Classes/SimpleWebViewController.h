//
//  SimpleWebViewController.h
//  adhawk
//
//  Created by Daniel Cloud on 7/27/12.
//  Copyright (c) 2012 Sunlight Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AdHawkBaseViewController.h"

@interface SimpleWebViewController : AdHawkBaseViewController <UIWebViewDelegate>
{
    IBOutlet UIWebView *webView;
    BOOL _authed;
    
}

@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, copy) NSURL *targetURL;

@end


