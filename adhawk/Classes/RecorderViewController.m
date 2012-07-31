//
//  RecorderViewController.m
//  adhawk
//
//  Created by Jim Snavely on 4/14/12.
//  Copyright (c) 2012 Sunlight Foundation 
//

#import "RecorderViewController.h"
#import "AdDetailViewController.h"
#import "AdhawkErrorViewController.h"
#import "InternalAdBrowserViewController.h"
#import "Settings.h"
#import "AdHawkAPI.h"
#import "AdHawkAd.h"


#define NSLog(__FORMAT__, ...) TFLog((@"%s [Line %d] " __FORMAT__), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)


extern const char * GetPCMFromFile(char * filename);

@implementation RecorderViewController

@synthesize recordButton, workingBackground, failView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


- (NSString*) getAudioFilePath {

    NSArray * dirPaths = NSSearchPathForDirectoriesInDomains(
                                                   NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = [dirPaths objectAtIndex:0];
    NSString *soundFilePath = [docsDir
                               stringByAppendingPathComponent:@"sound.caf"];
    return soundFilePath;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    failView = nil;
//    [[AdHawkAPI sharedInstance] searchForAdWithFingerprint:TEST_FINGERPRINT delegate:self];
//    [self setFailState:YES];
    _hawktivityAnimatedImageView = nil;
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleEnteredBackground:) 
                                                 name: UIApplicationDidEnterBackgroundNotification
                                               object: nil];
    [self setFailState:NO];
    
    [self setWorkingState:NO];
    
    recordButton.enabled = YES;
    [recordButton setImage:[UIImage imageNamed:@"IDbtndown"] forState:UIControlStateHighlighted];
    
    NSString *soundFilePath = [self getAudioFilePath];
                                
    NSURL *soundFileURL = [NSURL fileURLWithPath:soundFilePath];
        
    NSDictionary *recordSettings = [NSDictionary 
                                    dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithInt:AVAudioQualityMin],
                                    AVEncoderAudioQualityKey,
                                    [NSNumber numberWithInt:16], 
                                    AVEncoderBitRateKey,
                                    [NSNumber numberWithInt: 2], 
                                    AVNumberOfChannelsKey,
                                    [NSNumber numberWithFloat:44100.0], 
                                    AVSampleRateKey,
                                    nil];
    
    NSError *error = nil;
    
    audioRecorder = [[AVAudioRecorder alloc]
                     initWithURL:soundFileURL
                     settings:recordSettings
                     error:&error];
    
    if (error)
    {
        NSLog(@"error: %@", [error localizedDescription]);
        
    } else {
        [audioRecorder prepareToRecord];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    recordButton.hidden = NO;
}

- (void) viewDidDisappear:(BOOL)animated
{
    [self setFailState:NO];
    if (audioRecorder.recording) {
        [audioRecorder stop];
        [_timer invalidate];
    }
    [self setWorkingState:NO];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void) handleEnteredBackground:(NSNotification *)notification
{
    [self setFailState:NO];
}

- (void) retryButtonClicked
{
    [self setFailState:NO];
    [self setWorkingState:YES];
    [self recordAudio];
}

-(void) setFailState:(BOOL)isFail
{
    if (isFail && failView == nil) {
        AdhawkErrorViewController *errorVC = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"adhawkErrorVC"];
        failView = errorVC.view;
        [errorVC.popularResultsButton addTarget:self action:@selector(showBrowseWebView) forControlEvents:UIControlEventTouchUpInside];
        [errorVC.tryAgainButton addTarget:self action:@selector(handleTVButtonTouch) forControlEvents:UIControlEventTouchUpInside];
    }
    if (isFail) {
        [self.view addSubview:failView];
    }
    else {
        if ([failView isDescendantOfView:self.view]) {
            [failView removeFromSuperview];
        }
        failView = nil;
    }
}

- (void)setWorkingState:(BOOL)isWorking
{
    if(_hawktivityAnimatedImageView == nil)
    {
        UIImage *animImage = [UIImage animatedImageNamed:@"Animation_" duration:3.125];  
        _hawktivityAnimatedImageView = [[UIImageView alloc] initWithImage:animImage];
        _hawktivityAnimatedImageView.layer.position = recordButton.layer.position;
    }
    if (isWorking) {
        [self.view addSubview:_hawktivityAnimatedImageView];
        workingBackground.hidden = NO;
        recordButton.hidden = YES;
        recordButton.enabled = NO; 
    }
    else {
        [_hawktivityAnimatedImageView removeFromSuperview];
        workingBackground.hidden = YES;
        recordButton.hidden = NO;
        recordButton.enabled = YES; 
   }
}

-(void)handleTVButtonTouch
{
    BOOL locationEnabled = [CLLocationManager locationServicesEnabled];
    if (locationEnabled == YES && nil == _locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = [AdHawkAPI sharedInstance];
        _locationManager.desiredAccuracy = kCLLocationAccuracyKilometer;
        _locationManager.distanceFilter = 500;
        
    }
        
    [self setWorkingState:YES];
    [_locationManager startUpdatingLocation];
    [self recordAudio];
}

-(void) recordAudio
{
    if (!audioRecorder.recording)
    {
        [self setFailState:NO];
        [self setWorkingState:YES];
        _timer = [NSTimer scheduledTimerWithTimeInterval:15.0
                                         target:self
                                       selector:@selector(recordingTimerFinished:)
                                       userInfo:nil
                                        repeats:NO];
        [audioRecorder record];
    }
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [super prepareForSegue:segue sender:sender];
    if ([[segue identifier] isEqualToString:@"adSegue"])
    {
        // Get reference to the destination view controller
        AdDetailViewController *vc = [segue destinationViewController];
        NSLog(@"Segue to AdDetailView");
        
        // Pass any objects to the view controller here, like...
        NSURL *targetURL = [AdHawkAPI sharedInstance].currentAd.result_url;
        [vc setTargetURLString:[targetURL absoluteString]];
    }
}

- (void) recordingTimerFinished:(NSTimer*)theTimer
{
    
    NSLog(@"Timer complete");
    [self stopRecorder];
}

-(void)stopRecorder
{    
    if (audioRecorder.recording)
    {
        [audioRecorder stop];
        NSString *soundFilePath = [self getAudioFilePath];
        const char * fpCode = GetPCMFromFile((char*) [soundFilePath cStringUsingEncoding:NSASCIIStringEncoding]);
        NSString *fpCodeString = [NSString stringWithCString:fpCode encoding:NSASCIIStringEncoding];
        NSLog(@"Fingerprint generated");
        
//        [[AdHawkAPI sharedInstance] searchForAdWithFingerprint:TEST_FINGERPRINT delegate:self];
        [[AdHawkAPI sharedInstance] searchForAdWithFingerprint:fpCodeString delegate:self];
        

    } else if (audioPlayer.playing) {
        [audioPlayer stop];
    }
}


-(void) playAudio
{
    if (!audioRecorder.recording)
    {
        NSError *error;
        
        audioPlayer = [[AVAudioPlayer alloc] 
                       initWithContentsOfURL:audioRecorder.url                                    
                       error:&error];
        
        audioPlayer.delegate = self;
        
        if (error)
            NSLog(@"Error: %@", 
                  [error localizedDescription]);
        else
            [audioPlayer play];
    }
}

-(void)audioPlayerDidFinishPlaying:
(AVAudioPlayer *)player successfully:(BOOL)flag
{
    recordButton.enabled = YES;
}

-(void)audioPlayerDecodeErrorDidOccur:
(AVAudioPlayer *)player 
                                error:(NSError *)error
{
    NSLog(@"Decode Error occurred");
}
-(void)audioRecorderDidFinishRecording:
(AVAudioRecorder *)recorder 
                          successfully:(BOOL)flag
{
}
-(void)audioRecorderEncodeErrorDidOccur: (AVAudioRecorder *)recorder error:(NSError *)error
{
    NSLog(@"Encode Error occurred");
}


-(void) adHawkAPIDidReturnURL:(NSURL *)url
{
//    [self performSegueWithIdentifier:@"adSegue" sender:self];
    AdDetailViewController *vc = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"adDetailVC"];
    [vc setTargetURLString:[url absoluteString]];
    [self.navigationController pushViewController:vc animated:YES];
    [self setWorkingState:NO];
}

-(void) adHawkAPIDidReturnNoResult
{
    NSLog(@"No results for search");
    [self setWorkingState:NO];
    [self setFailState:YES];
}

-(void)showBrowseWebView
{
    InternalAdBrowserViewController *vc = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"internalBrowserVC"];
    NSURL *browseURL = [NSURL URLWithString:ADHAWK_BROWSE_URL];
    [self.navigationController pushViewController:vc animated:YES];
    [vc.webView loadRequest:[NSURLRequest requestWithURL:browseURL]];
}


@end
