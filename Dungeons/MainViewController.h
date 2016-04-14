//
//  MainViewController.h
//  Dungeons
//
//  Created by Ji Li on 2016-04-06.
//  Copyright © 2016 Andrew Meckling. All rights reserved.
//

#ifndef MainViewController_h
#define MainViewController_h

#import <UIKit/UIKit.h>

@interface MainViewController : UIViewController
{
    
}

@property (weak, nonatomic) IBOutlet UIWebView *UIWebView;
@property (weak, nonatomic) IBOutlet UIWebView *Login;
@property (weak, nonatomic) IBOutlet UIButton *startButton;


- (IBAction)Login:(UIButton *)sender;
- (IBAction)SoundButton:(UIButton *)sender;
@property (weak, nonatomic) IBOutlet UIButton *SoundButtonEffect;

@end

#endif /* MainViewController_h */
