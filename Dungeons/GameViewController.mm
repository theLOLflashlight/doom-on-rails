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
#include "ios_path.h"

#define BUFFER_OFFSET(i) ((char *)NULL + (i))
#define MAX_CHANNELS 30

#define BULLET_MIN 1000
#define BULLET_MAX 4000

@interface GameViewController ()
{
    Game*       _game;
    int         _bulletId;
    Model*      _projectileSprite;
    
    //AVAudioPlayer *GunSoundEffects;
    AVAudioPlayer *GunSoundEffects[MAX_CHANNELS];
    int _CurrentChannel;
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
        const CGPoint mouse = [sender locationInView:self.view];
        
        const mat4 view = _game->viewMatrix();
        const mat4 proj = _game->projMatrix();
        const vec4 viewport = _game->viewport();
        
        vec3 touchPos0 = unProject( vec3( mouse.x, -mouse.y, 0 ), view, proj, viewport );
        vec3 touchPos1 = unProject( vec3( mouse.x, -mouse.y, 1 ), view, proj, viewport );
        
        [self spawn_projectile: touchPos0  velocity: normalize( touchPos1 - touchPos0 )];
        
        //[self explosionAt: _game->_eyepos];
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
    
    auto fireball = std::make_shared<GLTexture>( ios_path( "Level0EnemyPos/enemy2.png" ) );
    
    _projectileSprite = new Model( ObjMesh( ios_path( "crate.obj" ) ), _game->_program );
    for ( auto& texture : _projectileSprite->_mesh.textures )
    {
        texture.material->map_Kd = fireball;
    }
    
    _bulletId = BULLET_MIN;
    
    _CurrentChannel = 0;
    
    NSData *GBSoundPath = [NSData dataWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"GunSoundEffect_1" ofType:@"wav"]];
    
    for(int i = 0; i < MAX_CHANNELS; i++) {
        
        GunSoundEffects[i] = [[AVAudioPlayer alloc]initWithData:GBSoundPath error:nil];
        
        [GunSoundEffects[i] prepareToPlay];
       

    }
}

- (void)viewDidLayoutSubviews
{
   
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

-(void) explosionAt:(glm::vec3) pos
             radius:(float)     radius
{
    for ( auto& ntt : _game->_entities )
    {
        if ( glm::distance( ntt.second.position, pos ) < radius )
        {
            GraphicalComponent* gfx = _game->findGraphicalComponent( ntt.first );
            if ( gfx )
                gfx->color = glm::vec4( 1, 0, 0, 1 );
        }
    }
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void) spawn_projectile:( glm::vec3 )pos velocity:( glm::vec3 ) vel
{
    const EntityId bulletId = _bulletId++;
    {
        GraphicalComponent bullet( bulletId );
        bullet.program = _game->_program.get();
        bullet.sprite = _projectileSprite;
        bullet.translucent = true;
        
        _game->_graphics.push_back( bullet );
    }
    {
        PhysicalComponent bullet( bulletId );
        bullet.position = pos;
        bullet.velocity = vel;
        
        _game->_physics.push_back( bullet );
    }
    
    [GunSoundEffects[_CurrentChannel] play];
    
    _CurrentChannel ++;
    
    if(_CurrentChannel == MAX_CHANNELS)
    {
        _CurrentChannel = 0;
    }
    
}

- (void) update
{
    _game->update( self.timeSinceLastUpdate );
}

- (void) glkView:(GLKView *)view
      drawInRect:(CGRect)rect
{
    _game->render();
}

@end
