//
//  MainViewController.h
//  Dungeons
//
//  Created by Ji Li on 2016-03-31.
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

- (IBAction)LoginSoundEffect:(UIButton *)sender;
- (IBAction)SoundButton:(UIButton *)sender;
@property (weak, nonatomic) IBOutlet UIButton *SoundButtonEffect;

@end

#endif /* MainViewController_h */
