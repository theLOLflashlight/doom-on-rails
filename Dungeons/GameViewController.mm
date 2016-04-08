//
//  GameViewController.m
//  Dungeons
//
//  Created by Andrew Meckling on 2016-03-22.
//  Copyright © 2016 Andrew Meckling. All rights reserved.
//

#import "GameViewController.h"
#import <OpenGLES/ES3/glext.h>
#import <AVFoundation/AVFoundation.h>
#import "Game.h"

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

@interface GameViewController ()
{
    Game*       _game;
    Entity*     _projectile;
    glm::vec3   _projectileVelocity;
    
    AVAudioPlayer *GunSoundEffects;
}

@property (strong, nonatomic) EAGLContext* context;

@end

@implementation GameViewController

//Tap handling - spawn projectile
- (void) handleTapGesture:(UITapGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateRecognized)
    {
        using namespace glm;
        
        const auto width = _game->_width / 2;
        const auto height = _game->_height / 2;
        const float aspectRatio = width / height;
        
        const CGPoint mouse = [sender locationInView:self.view];
        
        const mat4 view = lookAt( _game->_eyepos, _game->_eyelook, vec3( 0, 1, 0 ) );
        const mat4 proj = perspective< float >( radians( 80.0f ), aspectRatio, 0.1, 1000 );
        const vec4 viewport( 0, -height, width, height );
        
        vec3 touchPos0 = unProject( vec3( mouse.x, -mouse.y, 0 ), view, proj, viewport );
        vec3 touchPos1 = unProject( vec3( mouse.x, -mouse.y, 1 ), view, proj, viewport );
        
        [self spawn_projectile: touchPos0  velocity: normalize( touchPos1 - touchPos0 )];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.context = [[EAGLContext alloc] initWithAPI: kEAGLRenderingAPIOpenGLES3];

    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    //Q2 - double tap
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    tapGesture.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:tapGesture];
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    [EAGLContext setCurrentContext:self.context];
    
    _game = new Game( (GLKView*) self.view );
    
    //_projectile = &_game->_entities[ 0 ];
    //_projectileVelocity = glm::vec3();
    
    NSData *GBSoundPath = [NSData dataWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"GunSoundEffect_1" ofType:@"mp3"]];
    GunSoundEffects = [[AVAudioPlayer alloc]initWithData:GBSoundPath error:nil];
    [GunSoundEffects prepareToPlay];

}

- (void)viewDidLayoutSubviews
{
    NSLog(@"dd");
//        UIBlurEffect *blurEffect = [UIBlurEffect s];
//        UIVisualEffectView *blurEffectView = UIVisualEffectView( effect: blurEffect );
//        UIVisualEffectView *vibeEffectView = UIVisualEffectView( effect: UIVibrancyEffect( forBlurEffect: blurEffect ) );
//        
//        blurEffectView.frame = Hud.bounds
//        vibeEffectView.frame = Hud.bounds
//        
//        blurEffectView.addSubview( vibeEffectView )
//        Hud.insertSubview( blurEffectView, atIndex: 0 )
    
}

- (void)dealloc
{
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
    
    delete _game;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

    if ([self isViewLoaded] && ([[self view] window] == nil))
    {
        self.view = nil;
        
        [self tearDownGL];
        
        if ([EAGLContext currentContext] == self.context) {
            [EAGLContext setCurrentContext:nil];
        }
        self.context = nil;
    }

    // Dispose of any resources that can be recreated.
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void) spawn_projectile:( glm::vec3 )pos velocity:( glm::vec3 ) vel
{
    //const glm::mat4 view = glm::lookAt( _game->_eyepos, _game->_eyelook, glm::vec3( 0, 1, 0 ) );
    //_projectile->position = pos;
    //_projectileVelocity = vel;
    
    [GunSoundEffects play];
    
}

- (void) update
{
    _game->update( self.timeSinceLastUpdate );
    //_projectile->position += _projectileVelocity;
}

- (void) glkView:(GLKView *)view
         drawInRect:(CGRect)rect
{
    _game->render();
}

@end
