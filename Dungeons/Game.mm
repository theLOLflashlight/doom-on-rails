#include "Game.h"

#include "SOIL.h"
#include "ios_path.h"
#define DEMO 0

using namespace glm;
using namespace gl_enums::usage;
using std::shared_ptr;
using std::make_shared;
using std::string;
using std::vector;

const float SKYBOX_SIZE = 500;
const vec3 SKYBOX_VERTICES[] = {
    vec3( -SKYBOX_SIZE,  SKYBOX_SIZE, -SKYBOX_SIZE ),
    vec3( -SKYBOX_SIZE, -SKYBOX_SIZE, -SKYBOX_SIZE ),
    vec3(  SKYBOX_SIZE, -SKYBOX_SIZE, -SKYBOX_SIZE ),
    vec3(  SKYBOX_SIZE, -SKYBOX_SIZE, -SKYBOX_SIZE ),
    vec3(  SKYBOX_SIZE,  SKYBOX_SIZE, -SKYBOX_SIZE ),
    vec3( -SKYBOX_SIZE,  SKYBOX_SIZE, -SKYBOX_SIZE ),

    vec3( -SKYBOX_SIZE, -SKYBOX_SIZE,  SKYBOX_SIZE ),
    vec3( -SKYBOX_SIZE, -SKYBOX_SIZE, -SKYBOX_SIZE ),
    vec3( -SKYBOX_SIZE,  SKYBOX_SIZE, -SKYBOX_SIZE ),
    vec3( -SKYBOX_SIZE,  SKYBOX_SIZE, -SKYBOX_SIZE ),
    vec3( -SKYBOX_SIZE,  SKYBOX_SIZE,  SKYBOX_SIZE ),
    vec3( -SKYBOX_SIZE, -SKYBOX_SIZE,  SKYBOX_SIZE ),

    vec3( SKYBOX_SIZE, -SKYBOX_SIZE, -SKYBOX_SIZE ),
    vec3( SKYBOX_SIZE, -SKYBOX_SIZE,  SKYBOX_SIZE ),
    vec3( SKYBOX_SIZE,  SKYBOX_SIZE,  SKYBOX_SIZE ),
    vec3( SKYBOX_SIZE,  SKYBOX_SIZE,  SKYBOX_SIZE ),
    vec3( SKYBOX_SIZE,  SKYBOX_SIZE, -SKYBOX_SIZE ),
    vec3( SKYBOX_SIZE, -SKYBOX_SIZE, -SKYBOX_SIZE ),

    vec3( -SKYBOX_SIZE, -SKYBOX_SIZE,  SKYBOX_SIZE ),
    vec3( -SKYBOX_SIZE,  SKYBOX_SIZE,  SKYBOX_SIZE ),
    vec3(  SKYBOX_SIZE,  SKYBOX_SIZE,  SKYBOX_SIZE ),
    vec3(  SKYBOX_SIZE,  SKYBOX_SIZE,  SKYBOX_SIZE ),
    vec3(  SKYBOX_SIZE, -SKYBOX_SIZE,  SKYBOX_SIZE ),
    vec3( -SKYBOX_SIZE, -SKYBOX_SIZE,  SKYBOX_SIZE ),

    vec3( -SKYBOX_SIZE,  SKYBOX_SIZE, -SKYBOX_SIZE ),
    vec3(  SKYBOX_SIZE,  SKYBOX_SIZE, -SKYBOX_SIZE ),
    vec3(  SKYBOX_SIZE,  SKYBOX_SIZE,  SKYBOX_SIZE ),
    vec3(  SKYBOX_SIZE,  SKYBOX_SIZE,  SKYBOX_SIZE ),
    vec3( -SKYBOX_SIZE,  SKYBOX_SIZE,  SKYBOX_SIZE ),
    vec3( -SKYBOX_SIZE,  SKYBOX_SIZE, -SKYBOX_SIZE ),

    vec3( -SKYBOX_SIZE, -SKYBOX_SIZE, -SKYBOX_SIZE ),
    vec3( -SKYBOX_SIZE, -SKYBOX_SIZE,  SKYBOX_SIZE ),
    vec3(  SKYBOX_SIZE, -SKYBOX_SIZE, -SKYBOX_SIZE ),
    vec3(  SKYBOX_SIZE, -SKYBOX_SIZE, -SKYBOX_SIZE ),
    vec3( -SKYBOX_SIZE, -SKYBOX_SIZE,  SKYBOX_SIZE ),
    vec3(  SKYBOX_SIZE, -SKYBOX_SIZE,  SKYBOX_SIZE )
};

const float WATER_SIZE = SKYBOX_SIZE;

const vec3 WATER_QUAD[] = {
    vec3( -WATER_SIZE, 0, -WATER_SIZE ),
    vec3( -WATER_SIZE, 0,  WATER_SIZE ),
    vec3(  WATER_SIZE, 0,  WATER_SIZE ),
    vec3(  WATER_SIZE, 0, -WATER_SIZE )
};

const vec3 WATER_VERTICES[] = {
    vec3( -WATER_SIZE, 0, -WATER_SIZE ),
    vec3( -WATER_SIZE, 0,  WATER_SIZE ),
    vec3(  WATER_SIZE, 0,  WATER_SIZE ),
    
    vec3(  WATER_SIZE, 0,  WATER_SIZE ),
    vec3(  WATER_SIZE, 0, -WATER_SIZE ),
    vec3( -WATER_SIZE, 0, -WATER_SIZE )
};


Game::~Game()
{
}


Game::Game( GLKView* view )
    : _view( ([view bindDrawable], view) )

    , _width( _view.bounds.size.width * 2 )
    , _height( _view.bounds.size.height * 2 )

    , _startTime( 0 )
    , _currTime( _startTime )

    , _program( new GLProgram( ios_path( "MyShader.vs" ), ios_path( "MyShader.fs" ), "aPosition", "aNormal", "aTexCoord" ) )

    , _model( ObjMesh( ios_path( "crate.obj" ) ), _program )
    , _level( ObjMesh( ios_path( "Level0Layout.obj" ) ), _program )
    , _enemies( ObjMesh( ios_path( "Level0EnemyPos.obj" ) ), _program )
    , _rail( ios_path( "DemoRail.obj" ) )
    , _entities( {
#if DEMO
        Entity( &_model, vec3( 2, -.75, 0 ) ),
        Entity( &_model, vec3( 0, .75, 2 ) ),
        Entity( &_model, vec3( 0, 2, 0 ) )
#else
        Entity( &_model )
#endif
    } )

    , _skybox_texture( SOIL_load_OGL_cubemap(
        ios_path( "skybox/right.tga" ),
        ios_path( "skybox/left.tga" ),
        ios_path( "skybox/top.tga" ),
        ios_path( "skybox/bottom.tga" ),
        ios_path( "skybox/back.tga" ),
        ios_path( "skybox/front.tga" ),
        SOIL_LOAD_AUTO, SOIL_CREATE_NEW_ID,
        SOIL_FLAG_MIPMAPS | SOIL_FLAG_NTSC_SAFE_RGB | SOIL_FLAG_COMPRESS_TO_DXT ) )

    , _skybox_program( ios_path( "Skybox.vs" ), ios_path( "Skybox.fs" ), "aPosition" )
    , _skybox_buffer( SKYBOX_VERTICES, 36, STATIC_DRAW,
        _skybox_program.make_vert_attribute< vec3 >( "aPosition" ) )

    , _water_dudv( ios_path( "water/water_dudv.png" ) )
    , _water_normal( ios_path( "water/water_normal.png" ) )
    , _water_program( ios_path( "WaterShader.vs" ), ios_path( "WaterShader.fs" ), "aPosition" )
    , _water_quad( WATER_VERTICES, 6, STATIC_DRAW,
                   _water_program.make_vert_attribute< vec3 >( "aPosition" ) )
{
#if DEMO
    _entities[ 0 ].color = vec4( 0, 0, 1, 0.1 );
    _entities[ 1 ].color = vec4( 1, 0, 0, 0.1 );
    _entities[ 2 ].color = vec4( 0, 1, 0, 0.1 );
#endif
    
    glBindTexture( GL_TEXTURE_CUBE_MAP, _skybox_texture );
    glTexParameteri( GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE );
    glTexParameteri( GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE );
    glBindTexture( GL_TEXTURE_CUBE_MAP, 0 );

    //glGenFramebuffers( 3, &_water_fbo );

    //glBindFramebuffer( GL_FRAMEBUFFER, _water_reflect_fbo );
    //glBindFramebuffer( GL_FRAMEBUFFER, _water_refract_fbo );
    
    GLenum status;
    
    // REFLECT
    
    // COLOR TEXTURE
    glGenTextures( 1, &_water_reflect_texture );
    glBindTexture( GL_TEXTURE_2D, _water_reflect_texture );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
    glTexImage2D( GL_TEXTURE_2D, 0, GL_RGB, _width/2, _height/2, 0, GL_RGB, GL_UNSIGNED_BYTE, nullptr );
    glBindTexture( GL_TEXTURE_2D, 0 );
    
    // DEPTH BUFFER
    glGenRenderbuffers( 1, &_water_reflect_render_buffer );
    glBindRenderbuffer( GL_RENDERBUFFER, _water_reflect_render_buffer );
    glRenderbufferStorage( GL_RENDERBUFFER, GL_DEPTH_COMPONENT32F, _width, _height );
    glBindRenderbuffer( GL_RENDERBUFFER, 0 );
    
    // FRAME BUFFER
    glGenFramebuffers( 1, &_water_reflect_fbo );
    glBindFramebuffer( GL_FRAMEBUFFER, _water_reflect_fbo );
    glFramebufferTexture2D( GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _water_reflect_texture, 0 );
    
    glFramebufferRenderbuffer( GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _water_reflect_render_buffer );
    
    status = glCheckFramebufferStatus( GL_FRAMEBUFFER );
    glBindFramebuffer( GL_FRAMEBUFFER, 0 );
    if ( status != GL_FRAMEBUFFER_COMPLETE )
        throw status;

    // REFRACT
    
    // COLOR TEXTURE
    glGenTextures( 1, &_water_refract_texture );
    glBindTexture( GL_TEXTURE_2D, _water_refract_texture );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
    glTexImage2D( GL_TEXTURE_2D, 0, GL_RGB, _width * .75, _height * .75, 0, GL_RGB, GL_UNSIGNED_BYTE, nullptr );
    glBindTexture( GL_TEXTURE_2D, 0 );
    
    // DEPTH TEXTURE
    glGenTextures( 1, &_water_refract_depth_texture );
    glBindTexture( GL_TEXTURE_2D, _water_refract_depth_texture );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
    glTexImage2D( GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT32F, _width * .75, _height * .75, 0, GL_DEPTH_COMPONENT, GL_FLOAT, nullptr );
    glBindTexture( GL_TEXTURE_2D, 0 );
    
    // DEPTH BUFFER
    glGenRenderbuffers( 1, &_water_refract_render_buffer );
    glBindRenderbuffer( GL_RENDERBUFFER, _water_refract_render_buffer );
    glRenderbufferStorage( GL_RENDERBUFFER, GL_DEPTH_COMPONENT32F, _width, _height );
    glBindRenderbuffer( GL_RENDERBUFFER, 0 );

    // FRAME BUFFER
    glGenFramebuffers( 1, &_water_refract_fbo );
    glBindFramebuffer( GL_FRAMEBUFFER, _water_refract_fbo );
    glFramebufferTexture2D( GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _water_refract_texture, 0 );
    glFramebufferTexture2D( GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_TEXTURE_2D, _water_refract_depth_texture, 0 );
    
    glFramebufferRenderbuffer( GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _water_refract_render_buffer );
    
    status = glCheckFramebufferStatus( GL_FRAMEBUFFER );
    glBindFramebuffer( GL_FRAMEBUFFER, 0 );
    if ( status != GL_FRAMEBUFFER_COMPLETE )
        throw status;
    
    [_view bindDrawable];
    glClearColor( 0, 0, 0, 1 );
    
    //glMatrixMode( GL_PROJECTION );
    //gluPerspective( 75, _width / _height, 1, 3000 );
    glViewport( 0, 0, _width, _height );
    //glMatrixMode( GL_MODELVIEW );

    //glEnable( GL_BLEND );
    glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT );

    // AU: Astronomical Unit. (in meters.)
    const float AU = 1.496e+11f;

    vec3    sunPosition = normalize( vec3( -1, 1, -1 ) ) * AU;
    vec4    ambientComponent( 0.5, 0.5, 0.5, 1.0 );
    vec4    diffuseComponent( 0.5, 0.5, 0.1, 0.1 );
    vec4    specularComponent( 1, 1, 1, 1 );
    glm::float_t shininess = 10.0;
    
    _program->bind();
    glUniform3fv( _program->find_uniform( "uSunPosition" ), 1, &sunPosition[0] );
    //glUniform3fv( _program->find_uniform( "uSunColor" ), 1, &sunColor[0] );
    //glUniform3fv( _program->find_uniform( "uLightPosition" ), 1, &diffuseLightPosition[0] );
    glUniform4fv( _program->find_uniform( "uAmbientColor" ), 1, &ambientComponent[0] );
    glUniform4fv( _program->find_uniform( "uDiffuseColor" ), 1, &diffuseComponent[0] );
    glUniform4fv( _program->find_uniform( "uSpecularColor" ), 1, &specularComponent[0] );
    glUniform1f( _program->find_uniform( "uShininess" ), shininess );

    mat4 waterModel;

    _water_program.bind();
    glUniform3fv( _water_program.find_uniform( "uSunPosition" ), 1, &sunPosition[0] );
    glUniform3fv( _water_program.find_uniform( "uSunColor" ), 1, &specularComponent[0] );
    glUniform1i( _water_program.find_uniform( "uTextureRefle" ), 0 );
    glUniform1i( _water_program.find_uniform( "uTextureRefra" ), 1 );
    glUniform1i( _water_program.find_uniform( "uMapDepth" ), 2 );
    glUniform1i( _water_program.find_uniform( "uMapDuDv" ), 3 );
    glUniform1i( _water_program.find_uniform( "uMapNormal" ), 4 );

    glUniform4f( _water_program.find_uniform( "uColor" ), 0, 0.1, 1, 1 );
    glUniformMatrix4fv( _water_program.find_uniform( "uModelMatrix" ), 1, GL_FALSE, &waterModel[ 0 ][ 0 ] );
    
    glUseProgram( 0 );
    
    //_program->validate();
    //_skybox_program.validate();
    //_water_program.validate();
    
#if !DEMO
    size_t railsize = _rail.rail.size();
    _eyepos = _rail.rail[ _railidx % railsize ];
    _eyelook = _rail.rail[ (_railidx + 1) % railsize ];
    _eyelook2 = _rail.rail[ (_railidx + 3) % railsize ];
#endif
}


void Game::update( double step )
{
    _currTime += step;
    const double time = _currTime - _startTime;
    
#if DEMO
    const float eyedist = 5;
    //_eyepos = vec3( eyedist, eyedist * sin( time ) / 2, eyedist );/*
    _eyepos.x = eyedist * sin( time / 2 );
    _eyepos.y = 0.1 + eyedist / 4 + eyedist / 4 * sin( time / 6 );
    _eyepos.z = eyedist * cos( time / 2 );//*/
    _eyelook = vec3();
#else
    
    size_t railsize = _rail.rail.size();
    
    _eyelook = _rail.rail[ (_railidx + 1) % railsize ];
    _eyelook2 = _rail.rail[ (_railidx + 3) % railsize ];
    
    vec3 eyepos = _rail.rail[ _railidx ];
    if ( eyepos.x != _eyepos0.x || eyepos.y != _eyepos0.y || eyepos.z != _eyepos0.z )
    {
        _eyepos0 = eyepos;
        _time = time;
    }
    
    float a = (time - _time) / length( _eyelook - _eyelook2 ) * 6;
    vec3 eyelook = glm::mix( _eyelook, _eyelook2, a );
    
    a = (time - _time) / length( _eyepos0 - _eyelook ) * 6;
    
    eyepos = glm::mix( _eyepos0, _eyelook, a );
    if ( a > 1 ) {
        _railidx += 2;
        _railidx %= railsize;
    }
    
    eyepos.y -= 0.5;
    eyelook.y -= 0.5;
    
    _eyepos = eyepos;
    _eyelook = eyelook;
#endif
    
    float waveFactor = (time / 10);
    _water_program.bind();
    glUniform1f( _water_program.find_uniform( "uDuDvFactor" ), waveFactor );
    glUniform3fv( _water_program.find_uniform( "uEyePosition" ), 1, &_eyepos[0] );
    glUseProgram( 0 );
    
#if DEMO
    for ( int i = 0; i < _entities.size(); i++ )
        _entities[ i ].rotation[ i % 3 ] += step * 2;
#endif
}


void Game::render() const
{
    glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
    
    glEnable( GL_DEPTH_TEST );
    glEnable( GL_CULL_FACE );

    glCullFace( GL_BACK );

    vec3 eyepos = _eyepos;
    vec3 eyelook = _eyelook;
    
    const mat4 view = lookAt( eyepos, eyelook, vec3( 0, 1, 0 ) );

    const float aspectRatio = _width / _height;
    const mat4 proj = perspective< float >( radians( 80.0f ), aspectRatio, 0.1, 1000 );

    glActiveTexture( GL_TEXTURE0 );
    glBindTexture( GL_TEXTURE_2D, 0 );
    [_view bindDrawable];
    
    
    glEnable( GL_CLIP_DISTANCE(0) );
    
    // Render refLEction.
    glBindFramebuffer( GL_FRAMEBUFFER, _water_reflect_fbo );
    glViewport( 0, 0, (int) _width/2, (int) _height/2 );
    glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
    
    eyepos.y = -eyepos.y;
    eyelook.y = -eyelook.y;
    
    _program->bind();
    glUniform4f( _program->find_uniform( "uWaterPlane" ), 0, 1, 0, 0 );
    glUseProgram( 0 );
    
    draw_scene( lookAt( eyepos, eyelook, vec3( 0, 1, 0 ) ), proj );


    // Render refRAction
    glBindFramebuffer( GL_FRAMEBUFFER, _water_refract_fbo );
    glViewport( 0, 0, (int) (_width * .75), (int) (_height * .75) );
    glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
    
    _program->bind();
    glUniform4f( _program->find_uniform( "uWaterPlane" ), 0, -1, 0, 0 );
    glUseProgram( 0 );
    
    draw_scene( view, proj );
    
    glDisable( GL_CLIP_DISTANCE(0) );


    // Draw our scene.
    glEnable( GL_CULL_FACE );
    [_view bindDrawable];
    glViewport( 0, 0, (int) _width, (int) _height );
    //draw_scene( view, proj );
    _skybox_program.bind();
    glUniformMatrix4fv( _skybox_program.find_uniform( "uViewMatrix" ), 1, GL_FALSE, &view[ 0 ][ 0 ] );
    glUniformMatrix4fv( _skybox_program.find_uniform( "uProjMatrix" ), 1, GL_FALSE, &proj[ 0 ][ 0 ] );
    
    glUniform1i( _skybox_program.find_uniform( "uTexture" ), 0 );
    glActiveTexture( GL_TEXTURE0 );
    glBindTexture( GL_TEXTURE_CUBE_MAP, _skybox_texture );
    _skybox_buffer.draw( GL_TRIANGLES, 0, 36 );
    
    _program->bind();
    glUniformMatrix4fv( _program->find_uniform( "uViewMatrix" ), 1, GL_FALSE, &view[ 0 ][ 0 ] );
    glUniformMatrix4fv( _program->find_uniform( "uProjMatrix" ), 1, GL_FALSE, &proj[ 0 ][ 0 ] );
    glUniform4f( _program->find_uniform( "uColor" ), 1, 1, 1, 0 );
    
    _model.render( mat4(), view, proj );

    for ( const Entity& entity : _entities )
        entity.render( view, proj );
    
#if !DEMO
    glUniform4f( _program->find_uniform( "uColor" ), 1, 1, 1, 0 );
    _level.render( translate( mat4(), vec3( 0, -0.1, 0 ) ), view, proj );
#endif

    
    // Draw water.
    _water_program.bind();
    //glDisable( GL_CULL_FACE );
    glActiveTexture( GL_TEXTURE0 );
    glBindTexture( GL_TEXTURE_2D, _water_reflect_texture );
    
    glActiveTexture( GL_TEXTURE1 );
    glBindTexture( GL_TEXTURE_2D, _water_refract_texture );
    
    glActiveTexture( GL_TEXTURE2 );
    glBindTexture( GL_TEXTURE_2D, _water_refract_depth_texture );
    
    glActiveTexture( GL_TEXTURE3 );
    glBindTexture( GL_TEXTURE_2D, _water_dudv.glHandle );
    
    glActiveTexture( GL_TEXTURE4 );
    glBindTexture( GL_TEXTURE_2D, _water_normal.glHandle );
    
    
    glUniformMatrix4fv( _water_program.find_uniform( "uViewMatrix" ), 1, GL_FALSE, &view[ 0 ][ 0 ] );
    glUniformMatrix4fv( _water_program.find_uniform( "uProjMatrix" ), 1, GL_FALSE, &proj[ 0 ][ 0 ] );

    //glEnable( GL_BLEND );
    //glDisable( GL_DEPTH_TEST );
    //_water_quad.draw( GL_QUADS, 0, 4 );
    _water_quad.draw( GL_TRIANGLES, 0, 6 );
    //glEnable( GL_DEPTH_TEST );
    //glDisable( GL_BLEND );
    //glEnable( GL_CULL_FACE );
    
#if !DEMO
    glEnable( GL_BLEND );
    _enemies.render( translate( mat4(), vec3( 0, -0.1, 0 ) ), view, proj );
    glDisable( GL_BLEND );
#endif
}


void Game::draw_scene( glm::mat4 view, glm::mat4 proj ) const
{
    _skybox_program.bind();
    glUniformMatrix4fv( _skybox_program.find_uniform( "uViewMatrix" ), 1, GL_FALSE, &view[ 0 ][ 0 ] );
    glUniformMatrix4fv( _skybox_program.find_uniform( "uProjMatrix" ), 1, GL_FALSE, &proj[ 0 ][ 0 ] );

    glUniform1i( _skybox_program.find_uniform( "uTexture" ), 0 );
    glActiveTexture( GL_TEXTURE0 );
    glBindTexture( GL_TEXTURE_CUBE_MAP, _skybox_texture );
    _skybox_buffer.draw( GL_TRIANGLES, 0, 36 );

    _program->bind();
    glUniformMatrix4fv( _program->find_uniform( "uViewMatrix" ), 1, GL_FALSE, &view[ 0 ][ 0 ] );
    glUniformMatrix4fv( _program->find_uniform( "uProjMatrix" ), 1, GL_FALSE, &proj[ 0 ][ 0 ] );
    glUniform4f( _program->find_uniform( "uColor" ), 1, 1, 1, 0 );

    _model.render( mat4(), view, proj );

    for ( const Entity& entity : _entities )
        entity.render( view, proj );
    
#if !DEMO
    glUniform4f( _program->find_uniform( "uColor" ), 1, 1, 1, 0 );
    _level.render( translate( mat4(), vec3( 0, -0.1, 0 ) ), view, proj );
    glEnable( GL_BLEND );
    _enemies.render( translate( mat4(), vec3( 0, -0.1, 0 ) ), view, proj );
    glDisable( GL_BLEND );
#endif
}
