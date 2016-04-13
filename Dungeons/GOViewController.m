//
//  GOViewController.m
//  Dungeons
//
//  Created by Ji Li on 2016-04-12.
//  Copyright © 2016 Andrew Meckling. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GOViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface GOViewController ()
{
    AVAudioPlayer *BGSound;
}

@end

@implementation GOViewController

-(void) viewDidLoad
{
    NSData *FilePath_BG = [NSData dataWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"GameOver" ofType:@"gif"]];
    //self.UIWebView.backgroundColor = [UIColor blackColor];
    self.GameOver.userInteractionEnabled = NO;
    [self.GameOver loadData:FilePath_BG MIMEType:@"image/gif" textEncodingName:nil baseURL:nil];
    
    
    NSData *GBSoundPath = [NSData dataWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"Game Over sound effect" ofType:@"mp3"]];
    BGSound = [[AVAudioPlayer alloc]initWithData:GBSoundPath error:nil];
    
    [BGSound prepareToPlay];
    [BGSound play];
}

@end