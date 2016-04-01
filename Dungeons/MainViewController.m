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

}

- (void)didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];

}

- (IBAction)LoginSoundEffect:(UIButton *)sender {
    
    if (SoundSwitch)
    {
        [ButtonSound prepareToPlay];
        [ButtonSound play];
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