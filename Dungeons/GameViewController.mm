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
#import "GameCppVariables.hpp"

#define BUFFER_OFFSET(i) ((char *)NULL + (i))
#define SFXINSTANCES 5
#define NSPoint CGPoint
#define NSUInteger UInt

@interface GameViewController ()
{
    Game*       _game;
    Entity*     _projectile;
    glm::vec3   _projectileVelocity;
    
    AVAudioPlayer *GunSoundEffects[SFXINSTANCES];
    int _currSound;
    
    //For swipe action.
    CGFloat _maxRadius;
    //var _maxTranslationY : CGFloat = 0;
    CGFloat _prevTranslationX; //for drawing lines
    CGFloat _prevTranslationY;
    NSMutableArray *_translationPoints;
    bool _noSwipe;
    bool _swipeHit;
    
    CGRect screenSize;// : CGRect = UIScreen.mainScreen().bounds;
    CGSize imageSize;// = CGSize(width: 200, height: 200); //arbitrary initialization
    UIImageView * _imageView;// = UIImageView();
    
    UIBezierPath* _myBezier;// = UIBezierPath();
    CGFloat bezierDuration;// = Float(1); //duration of bezier on screen (in seconds)
    
    //to track swipe running or not
    CGFloat _currBezierDuration;// = -0.00001; //hard-coded time below 0
    bool _currSwipeDrawn;// = false;
    
    
    //For camera, swipe
    //Camera stuff
    CGFloat _baseHorizontalAngle, _baseVerticalAngle;
    CGFloat currHorizontalAngle, currVerticalAngle;
    CGFloat rotationSpeed;
    /* //original swift code
    var modelViewProjectionMatrix:GLKMatrix4 = GLKMatrix4Identity
    var normalMatrix: GLKMatrix3 = GLKMatrix3Identity
    
    var modelViewMatrix: GLKMatrix4 = GLKMatrix4Identity
    
    //Accessible static var - position
    static var position: GLKVector3 = GLKVector3Make(0, 0.5, 5)
    var direction: GLKVector3 = GLKVector3Make(0,0,0)
    var up: GLKVector3 = GLKVector3Make(0, 1, 0)
    
    
    var currProjectileCoord: UILabel!;
    
    var horizontalMovement: GLKVector3 = GLKVector3Make(0, 0, 0)
    var _baseHorizontalAngle : Float = 0
    var _baseVerticalAngle : Float = 0
    var currhorizontalAngle: Float = 0
    var currverticalAngle: Float = 0
    
    var rotationSpeed: Float = 0.005
    
    var vertexArray: GLuint = 0
    var vertexBuffer: GLuint = 0
    
    var context: EAGLContext? = nil
    var effect: GLKBaseEffect? = nil
    
    var _myBezier = UIBezierPath();
    
    let bezierDuration = Float(1); //duration of bezier on screen (in seconds)
    
    //to track swipe running or not
    var _currBezierDuration = -0.00001; //hard-coded time below 0
    var _currSwipeDrawn = false;
     */
    //End of for camera, swipe
    
    //For sound - Apr 9
    //sound setup
    
    
    //NSDate *_lastDate[64];
    /* //Original swift code
    // Grab the path, make sure to add it to your project!
    let filePath = "footsteps_gravel";
    var sound : NSURL = NSBundle.mainBundle().URLForResource("footsteps_gravel", withExtension: "wav")!;
    //var audioPlayer = AVAudioPlayer()
    var mySound: SystemSoundID = 0;
    public var themePlayer : AVAudioPlayer!;
    var soundPlayer : AVAudioPlayer!;
    var soundPlayer2 : AVAudioPlayer!;
    
    //Make an arraylist keeping track of each audio played, and remove each AVPAudioPlayer from the arraylist as each of them has completed its track, is the plan - though, still have to figure out how to set delegate and such, as to-do.
    //
    var AVAudioPlayers : [AVAudioPlayer] = [];
    
    //For other iOS stuff.
    typealias NSPoint = CGPoint;
    typealias NSUInteger = UInt;
    
    var _lastDate = [NSDate?](count: 64, repeatedValue: nil);
    */
    //End of for sound - Apr 9
    
    AVAudioPlayer *soundPlayer, *soundPlayer2;
    AVAudioPlayer *themePlayer;
    
    
    //Make an arraylist keeping track of each audio played, and remove each AVPAudioPlayer from the arraylist as each of them has completed its track, is the plan - though, still have to figure out how to set delegate and such, as to-do.
    //
    AVAudioPlayer *AVAudioPlayers[5];
    
    //For other iOS stuff.
    //typedef CGPoint NSPoint;
    //typedef UInt8 NSUInteger;
    
    //SystemSoundID *mySound = 0;
    //UILabel *currProjectileCoord; //Swift: var currProjectileCoord: UILabel!;
    
    NSDate *_lastDate[64];
    GameCppVariables GCV;
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
    
    //Handle tap: Shoot projectile
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    tapGesture.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:tapGesture];
    
    //Handle pan: Swipe
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    [panGesture setMinimumNumberOfTouches:1];
    [panGesture setMaximumNumberOfTouches:1];
    [self.view addGestureRecognizer:panGesture];
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    [EAGLContext setCurrentContext:self.context];
    
    _game = new Game( (GLKView*) self.view );
    
    _projectile = &_game->_entities[ 0 ];
    _projectileVelocity = glm::vec3();
    
    NSData *GBSoundPath = [NSData dataWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"GunSoundEffect_1" ofType:@"mp3"]];
    for(int i = 0; i < SFXINSTANCES; i++) {
        GunSoundEffects[i] = [[AVAudioPlayer alloc]initWithData:GBSoundPath error:nil];
        [GunSoundEffects[i] prepareToPlay];
    }
    
    //Initialization of variables
    _currSound = 0;
    screenSize = [[UIScreen mainScreen] bounds];// : CGRect = UIScreen.mainScreen().bounds;
    imageSize = CGSizeMake(200, 200);// = CGSize(width: 200, height: 200); //arbitrary initialization
    _myBezier = [[UIBezierPath alloc] init];// = UIBezierPath();
    bezierDuration = 1;// = Float(1); //duration of bezier on screen (in seconds)
    //to track swipe running or not
    _currBezierDuration= -0.00001;// = -0.00001; //hard-coded time below 0
    _currSwipeDrawn = false;// = false;
    
    //[NSDate?](count: 64, repeatedValue: nil)
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

- (void)handlePanGesture: (UIPanGestureRecognizer *)recognizer {
    CGPoint translation = [recognizer translationInView:self.view];
    CGPoint location = [recognizer locationInView:self.view];
    
    //Actually, just get furthest radius from the origin.
    GLKVector2 radiusVec = GLKVector2Make(translation.x, translation.y);
    CGFloat radLength = GLKVector2Length(radiusVec);
    
    if(recognizer.state == UIGestureRecognizerStateBegan) {
        _maxRadius = 0;
        _noSwipe = false;
        [_translationPoints removeAllObjects];
    }
    if(recognizer.state == UIGestureRecognizerStateEnded) {
        _noSwipe = false;
        if(radLength >= 80) { //valid swipe
            NSString *swipeSound;
            NSString *swipeSoundExt = @"mp3";
            if(_swipeHit) {
                swipeSound = @"sword-clash1";
            }
            else {
                swipeSound = @"swipe_whiff";
            }
            
            if(NSString *path = [[NSBundle mainBundle] pathForResource:swipeSound ofType: swipeSoundExt]) { //J: Not sure about this conversion from swift
                NSURL *soundURL = [NSURL fileURLWithPath:path]; //Can check this code later ...
                
                NSError *error;
                try { //J: Not sure about this conversion from Swift
                    soundPlayer2 = [[AVAudioPlayer alloc] initWithContentsOfURL:(NSURL *)soundURL error:nil];
                    [soundPlayer2 prepareToPlay];
                    [soundPlayer2 play];
                }
                catch(NSException *exception) {
                }
            }
            _currBezierDuration = bezierDuration;
            _currSwipeDrawn = true;
        }
    }
    
    
    if(radLength > _maxRadius) {
        _maxRadius = radLength;
    }
    
    //cancel gesture if moving backwards from the furthest radius from the origin (as opposed to total translation) by 6px.
    //So yes, you can zigzag a lot if you wanted to.
    if(radLength < _maxRadius - 6) {
        //_noSwipe = true;
    }
    
    //draw line
    //ie. create the _translationPoints
    if(!_noSwipe) {
        //From stackoverflow ...
        [_translationPoints addObject:[NSValue valueWithCGPoint:CGPointMake(location.x, location.y)]];
    }
    //print("radLength: \(radLength); _maxRadius: \(_maxRadius)");
    
    
    
    //let point: CGPoint = recognizer.translationInView(self.view)
    
    
    if(recognizer.state == UIGestureRecognizerStateBegan) {
        //_prevHorizontalAngle
        _baseHorizontalAngle += currHorizontalAngle; //had missed the + increment over the previous ...
        _baseVerticalAngle += currVerticalAngle;
        //currhorizontalAngle = 0;
        //currverticalAngle = 0;
    }
    currHorizontalAngle = -translation.x * rotationSpeed;
    currVerticalAngle = translation.y * rotationSpeed;
}
/*
 @IBAction func MoveCamera(sender: UIButton) {
 GameViewController.position = GLKVector3Subtract(GameViewController.position, direction)
 }
 */

//J: Start of Swift code/functions to be converted as of Apr 9



//Time since the last iteration of calling this method. Original intention is for running the code, and tracking time independently of frame rate.
//Each place in code calling this is to use a different Int for 'closest-to-accurate' results (though it would not include the time after retrieving the time and updating the time, so the value would be less, or not include the time spent in retrieving the NSDate before retrieving timeDiff, ie. timeDiff would not include such time).
- (double)timeSinceLastIter: (int)timePointIndex {
    NSDate *newTime = [[NSDate alloc] init];
    double timeDiff = 0; //this would be the first time; there would be no time before this one occurred.
    int lastDateCount = (sizeof(_lastDate) / sizeof(_lastDate[0]));
    if(timePointIndex < lastDateCount) {
        if(_lastDate[timePointIndex] != nil) { //if an NSDate exists, then do the following
            timeDiff = [newTime timeIntervalSinceDate:_lastDate[timePointIndex]]; //Had a "!" in the Swift version, but this is pretty much what Objective-C already does - ie. assume the existence of the object //provided misleading error info - where I declared timeDiff resolved an error of 'not matching array type' apparently
        }
    }
    
    //if let timeDiff = newTime.timeIntervalSinceDate(_lastDate[timePointIndex]);
    
    /* //Not doing this in Objective-C. Simply make a precondition restricting to 64 elements instead.
    //append array elements such that this array would be long enough to store the element at timePointIndex
    if(!(timePointIndex < _lastDate.count)) {
        _lastDate = _lastDate + [NSDate?](count: timePointIndex - (_lastDate.count - 1), repeatedValue: nil);
    }
     */
    _lastDate[timePointIndex] = newTime;
    return timeDiff;
}

//For drawing lines - from http://stackoverflow.com/questions/25229916/how-to-procedurally-draw-rectangle-lines-in-swift-using-cgcontext

/*
- (UIImage *) drawSwipeLine : (CGSize) size {
    // Setup our context
    let bounds = CGRect(origin: CGPoint.zero, size: size)
    let opaque = false
    let scale: CGFloat = 0
    UIGraphicsBeginImageContextWithOptions(size, opaque, scale)
    let context = UIGraphicsGetCurrentContext()
    
    // Setup complete, do drawing here
    CGContextSetStrokeColorWithColor(context, UIColor.blueColor().CGColor)
    CGContextSetLineWidth(context, 4.0)
    
    CGContextStrokeRect(context, bounds)
    
    CGContextBeginPath(context)
    
    
    let timesinceLast = timeSinceLastIter(0);
    if(!_noSwipe) { //condition to erase line if swipe ended
        //Draw bezier
        //Maybe a cubic bezier curve?
        _myBezier = UIBezierPath()
        let myMicroBezier = UIBezierPath();
        
        //Set control points c0, c1, c2, and c3 for the path myBezierPath()
        var c0, c1, c2, c3 : CGPoint;
        let bezierInterval = 3; //have to make sure this is divisible by 3.
        //myBezier.moveToPoint(CGPoint(x: 0,y: 0));
        if(!(_translationPoints.count < 1)) {
            //initialization
            //c0 = _translationPoints[0]; //adding this because xcode is stupid
            c1 = _translationPoints[0];
            c2 = _translationPoints[0];
            c3 = _translationPoints[0]; //set origin point
            //var currCurvePos = 1;
            
            //draw each line, as evident from _translationPoints
            for(var i=1; i < _translationPoints.count; i++) {
                //CGContextMoveToPoint(context, _translationPoints[i-1].x, _translationPoints[i-1].y);
                
                //build bezier curve
                if(i%(bezierInterval/3) == 0) { //every point, add a new control point to bezier curve
                    //shift all of the control points by one
                    c0 = c1;
                    c1 = c2;
                    c2 = c3;
                    c3 = _translationPoints[i];
                    
                    //draw the c0,c1,c2,c3 bezier curve every 3 additional control points.
                    if(i%(bezierInterval) == 0) { //becomes 0 ... making sometimes a straight line ... maybe the 'last line' being different in how Bezier might handle it? Oh, it's because of the closePath, and that apparently applying to addCurveToPoint ...
                        _myBezier.moveToPoint(c0);
                        _myBezier.addCurveToPoint(c3, controlPoint1: c1, controlPoint2: c2);
                    }
                }
                
                //get values greater than those truncated from dividing by bezierInterval, ie. values greater than the highest value quantized by bezierInterval, and draw normally according to that
                let highestQuantizedVal = (_translationPoints.count / bezierInterval) * bezierInterval;
                if(i > highestQuantizedVal) {
                    myMicroBezier.moveToPoint(_translationPoints[i-1]);
                    myMicroBezier.addLineToPoint(_translationPoints[i]);
                }
                //CGContextAddLineToPoint(context, _translationPoints[i].x, _translationPoints[i].y);
            }
            
            //draw bezier curve from those control points
            _myBezier.lineWidth = 5;
            //Maybe error occurs when trying to access c0 when c0 would no longer exist, ie. be out of scope?
            //myBezier.addClip();
            //myBezier.closePath() //may be the cause
            UIColor.redColor().setStroke();
            
            //myMicroBezier.lineWidth = 5;
            //UIColor.greenColor().setStroke();
            //myMicroBezier.stroke();
        }
    }
    //Fading swipe effect
    if(_currBezierDuration >= 0 && _currSwipeDrawn) {
        _currBezierDuration -= timesinceLast; //reserving 0 for this
        
        //fade only halfway through the swipe
        let alpha = min(1, Float(_currBezierDuration)/Float(bezierDuration * 0.66));
        UIColor(red: 1,green: 0, blue: 0, alpha:CGFloat(alpha)).setStroke();
        _myBezier.stroke();
        
        if(_currBezierDuration <= 0) {
            _translationPoints.removeAll();
            _currSwipeDrawn = false;
        }
    }
    //draw min to max - so, diagonally
    //        CGContextMoveToPoint(context, CGRectGetMaxX(bounds), CGRectGetMinY(bounds))
    //        CGContextAddLineToPoint(context, CGRectGetMinX(bounds), CGRectGetMaxY(bounds))
    //CGContextStrokePath(context)
    
    // Drawing complete, retrieve the finished image and cleanup
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image
}
*/
-(void) ThemeSound {
    if(NSString *path = [[NSBundle mainBundle] pathForResource:@"footsteps_gravel" ofType: @"wav"]) { //J: Not sure about this conversion from swift
        NSURL *soundURL = [NSURL fileURLWithPath:path]; //Can check this code later ...
        
        NSError *error;
        try { //J: Not sure about this conversion from Swift
            themePlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:(NSURL *)soundURL error:nil];
            [themePlayer prepareToPlay];
            themePlayer.numberOfLoops = -1;
            [themePlayer play];
        }
        catch(NSException *exception) {
        }
    }
    
    //Original Swift code
    /*
    if let path = NSBundle.mainBundle().pathForResource("footsteps_gravel", ofType: "wav") {
        let soundURL = NSURL(fileURLWithPath:path)
        
        var error:NSError?
        do {
            themePlayer = try AVAudioPlayer(contentsOfURL: soundURL);
            themePlayer.prepareToPlay()
            themePlayer.numberOfLoops = -1;
            themePlayer.play()
        }
        catch {
        }
    }*/
}
/* Currently not used
- (void) cameraMovement
{
    float horizontalAngle = _baseHorizontalAngle + currHorizontalAngle;
    float verticalAngle = _baseVerticalAngle + currVerticalAngle;
    
    //for animationProgress of shake
    if(GCV.animationProgress > 1) {
        GCV.animationProgress = 1;
    }
    if(GCV.animationProgress < 1) {
        GCV.animationProgress += 1.0 / 45.0;
        float shakeMag;
        if(GCV.animationProgress < 0.70) {
            shakeMag = 0.9 * 0.4;
        }
        else {
            shakeMag = (0.9 - (GCV.animationProgress - 0.7) * 0.9 / 0.3) * 0.4; //after reaching 0.7 progress (when sound starts to dwindle), linearly decrease max magnitude to 0
        }
        //modelViewMatrix = GLKMatrix4Translate(modelViewMatrix, Float(arc4random())*shakeMag, Float(arc4random())*shakeMag, 0);
        //GLKVector3Make(position.x + Float(arc4random())*shakeMag, position.y + Float(arc4random())*shakeMag, position.z + Float(arc4random())*shakeMag);
        horizontalAngle += (arc4random() / UINT32_MAX) * shakeMag;
        verticalAngle += (arc4random() / UINT32_MAX) * shakeMag;
    }
    
    GCV.direction = GLKVector3Make(cosf(verticalAngle) * sinf(horizontalAngle),
                               sinf(verticalAngle),
                               cosf(verticalAngle) * cosf(horizontalAngle));
    
    GCV.horizontalMovement = GLKVector3Make(sinf(horizontalAngle - M_PI_2), 0, cosf(horizontalAngle - M_PI_2));
    //print("horizontalAngle: \(horizontalAngle); verticalAngle: \(verticalAngle)");
}
 */

//Jacob: Shake input handler
-(void) motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (motion == UIEventSubtypeMotionShake) { //just having earthquake for now
        //shake method here
        //Cast spell
        
        GCV.animationProgress = 0; //begins the animation of earthquake
        
        
        if(NSString *path = [[NSBundle mainBundle] pathForResource:@"magic-quake2" ofType: @"mp3"]) { //J: Not sure about this conversion from swift
            NSURL *soundURL = [NSURL fileURLWithPath:path]; //Can check this code later ...
            
            NSError *error;
            try { //J: Not sure about this conversion from Swift
                soundPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:(NSURL *)soundURL error:nil];
                [soundPlayer prepareToPlay];
                [soundPlayer play];
            }
            catch(NSException *exception) {
            }
        }
        /*
        if let path = NSBundle.mainBundle().pathForResource("magic-quake2", ofType: "mp3") {
            let soundURL = NSURL(fileURLWithPath:path)
            
            var error:NSError?
            do {
                soundPlayer = try AVAudioPlayer(contentsOfURL: soundURL);
                soundPlayer.prepareToPlay()
                //No loops
                soundPlayer.play()
            }
            catch {
            }
        }
        */
        
        //Right now, it simply shakes the camera, but maybe shaking the world instead could be considered?
    }
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
    _projectile->position = pos;
    _projectileVelocity = vel;
    
    [GunSoundEffects[_currSound++] play];
    if(_currSound == SFXINSTANCES) {
        _currSound = 0;
    }
    
}

- (void) update
{
    _game->update( self.timeSinceLastUpdate );
    _projectile->position += _projectileVelocity;
    
    
    //update line
    /* //Not yet implemented
    UIImage image = [drawSwipeLine size:imageSize]
    _imageView.image = image
     */
}

- (void) glkView:(GLKView *)view
      drawInRect:(CGRect)rect
{
    _game->render();
}

@end
