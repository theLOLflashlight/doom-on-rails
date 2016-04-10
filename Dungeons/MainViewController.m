//
//  MainViewController.m
//  Dungeons
//
//  Created by Ji Li on 2016-03-31.
//  Copyright © 2016 Andrew Meckling. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "MainViewController.h"
#import "GameViewController.h"

@interface MainViewController()
{
    AVAudioPlayer *ButtonSound;
    AVAudioPlayer *BGSound;
    bool SoundSwitch;
}

@end

@implementation MainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    SoundSwitch = true;
    
    NSData *FilePath_BG = [NSData dataWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"BGT1" ofType:@"gif"]];
    //self.UIWebView.backgroundColor = [UIColor blackColor];
    self.UIWebView.userInteractionEnabled = NO;
    [self.UIWebView loadData:FilePath_BG MIMEType:@"image/gif" textEncodingName:nil baseURL:nil];
    
    
    NSData *FilePath_LG = [NSData dataWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"Start" ofType:@"gif"]];
    //self.Login.backgroundColor = [UIColor blackColor];
    //self.Login.scrollView.contentOffset =  CGPointMake(0, 700);
    self.Login.userInteractionEnabled = NO;
    [self.Login loadData:FilePath_LG MIMEType:@"image/gif" textEncodingName:nil baseURL:nil];
    
    NSData *ButtonSoundPath = [NSData dataWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"ButtonPress" ofType:@"wav"]];
    ButtonSound = [[AVAudioPlayer alloc]initWithData:ButtonSoundPath error:nil];
    
    NSData *GBSoundPath = [NSData dataWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"DOOM" ofType:@"mp3"]];
    BGSound = [[AVAudioPlayer alloc]initWithData:GBSoundPath error:nil];
    
    [BGSound prepareToPlay];
    
    if (SoundSwitch) {
        
        UIImage *SoundButtonImage = [UIImage imageNamed:@"SoundOn.png"];
        [self.SoundButtonEffect setImage:SoundButtonImage forState:(UIControlStateNormal)];
        [BGSound play];
    }
    else
    {
        UIImage *SoundButtonImage = [UIImage imageNamed:@"SoundOff.png"];
        [self.SoundButtonEffect setImage:SoundButtonImage forState:(UIControlStateNormal)];
    }
    
    
    GameViewController *gvc = [[GameViewController alloc] init];
    //gvc.data = _label.text; // Set the exposed property
    //[self.navigationController pushViewController:secondViewController animated:YES];
    
}

//J: For shake method. This is in contrast to in Swift where this were put into the GameViewController.
-(BOOL)canBecomeFirstResponder {
    return YES;
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self becomeFirstResponder];
}

//J: End for shake method

- (void)didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];
    
}

- (IBAction)Login:(UIButton *)sender {
    
    if (SoundSwitch)
    {
        [ButtonSound prepareToPlay];
        [ButtonSound play];
        
        //Disable the main menu sound.
        [BGSound pause];
    }
    
}

- (IBAction)SoundButton:(UIButton *)sender {
    
    if (SoundSwitch) {
        
        UIImage *SoundButtonImage = [UIImage imageNamed:@"SoundOff.png"];
        [self.SoundButtonEffect setImage:SoundButtonImage forState:(UIControlStateNormal)];
        SoundSwitch = false;
        [BGSound pause];
    }
    else
    {
        UIImage *SoundButtonImage = [UIImage imageNamed:@"SoundOn.png"];
        [self.SoundButtonEffect setImage:SoundButtonImage forState:(UIControlStateNormal)];
        SoundSwitch = true;
        [BGSound play];
    }
}
@end