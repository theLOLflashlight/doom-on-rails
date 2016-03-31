#include "Game.h"

#include "SOIL/SOIL.h"

#include <chrono>
#define DEMO

using namespace glm;
using namespace gl_enums::usage;
using std::shared_ptr;
using std::make_shared;
using std::string;
using std::vector;
using std::chrono::duration_cast;
using std::chrono::seconds;

const GLfloat vertices[] = {
    -0.5f, -0.5f, 0.0f,
    0.5f, -0.5f, 0.0f,
    0.5f,  0.5f, 0.0f,
};

double current_time()
{
    return duration_cast< seconds >( std::chrono::system_clock::now().time_since_epoch() ).count();
}

const float SKYBOX_SIZE = 500;
const vec3 VERTICES[] = {
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

#define SOIL_LOAD_OGL_TEXTURE_OPTIONS   \
SOIL_LOAD_AUTO, SOIL_CREATE_NEW_ID,     \
SOIL_FLAG_MIPMAPS | SOIL_FLAG_NTSC_SAFE_RGB | SOIL_FLAG_COMPRESS_TO_DXT

Game::~Game()
{
}

Game::Game( int width, int height )
: _width( (GLfloat) width )
, _height( (GLfloat) height )
, _startTime( current_time() )
, _currTime( _startTime )
, _program( new GLProgram( "MyShader.vs", "MyShader.fs",
                          "aPosition", "aNormal", "aTexCoord" ) )
, _model( ObjMesh( "crate.obj" ), _program )
, _level( ObjMesh( "Level0Layout.obj" ), _program )
, _enemies( ObjMesh( "Level0EnemyPos.obj" ), _program )
, _rail( "DemoRail.obj" )
, _entities( {
#ifdef DEMO
    Entity( &_model, vec3( 2, -.75, 0 ) ),
    Entity( &_model, vec3( 0, .75, 2 ) ),
    Entity( &_model, vec3( 0, 2, 0 ) )
#endif
} )
, _skybox_texture( SOIL_load_OGL_cubemap(
                                         "skybox/right.tga",
                                         "skybox/left.tga",
                                         "skybox/top.tga",
                                         "skybox/bottom.tga",
                                         "skybox/back.tga",
                                         "skybox/front.tga",
                                         SOIL_LOAD_OGL_TEXTURE_OPTIONS ) )
, _skybox_program( "Skybox.vs", "Skybox.fs", "aPosition" )
, _skybox_buffer( VERTICES, 36, STATIC_DRAW,
                 _skybox_program.make_vert_attribute< vec3 >( "aPosition" ) )
, _water_dudv( "Water/water_dudv.png" )
, _water_normal( "Water/water_normal.png" )
, _water_program( "WaterShader.vs", "WaterShader.fs", "aPosition" )
, _water_quad( WATER_QUAD, sizeof( WATER_QUAD ), STATIC_DRAW,
              _water_program.make_vert_attribute< vec3 >( "aPosition" ) )
{
#ifdef DEMO
    _entities[ 0 ].color = vec4( 0, 0, 1, 0.1 );
    _entities[ 1 ].color = vec4( 1, 0, 0, 0.1 );
    _entities[ 2 ].color = vec4( 0, 1, 0, 0.1 );
#endif
    
    glBindTexture( GL_TEXTURE_CUBE_MAP, _skybox_texture );
    glTexParameteri( GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE );
    glTexParameteri( GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE );
    glBindTexture( GL_TEXTURE_CUBE_MAP, 0 );
    
#undef SOIL_LOAD_OGL_TEXTURE_OPTIONS
    glGenFramebuffers( 2, &_water_fbo );
    
    glBindFramebuffer( GL_FRAMEBUFFER, _water_fbo[ 0 ] );
    glDrawBuffer( GL_COLOR_ATTACHMENT0 );
    glBindFramebuffer( GL_FRAMEBUFFER, _water_fbo[ 1 ] );
    glDrawBuffer( GL_COLOR_ATTACHMENT0 );
    
    glGenTextures( 3, &_water_textures );
    
    glBindTexture( GL_TEXTURE_2D, _water_textures[ 0 ] );
    glTexImage2D( GL_TEXTURE_2D, 0, GL_RGB, width/2, height/2, 0,
                 GL_RGB, GL_UNSIGNED_BYTE, nullptr );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
    glBindFramebuffer( GL_FRAMEBUFFER, _water_fbo[ 0 ] );
    glFramebufferTexture( GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, _water_textures[ 0 ], 0 );
    
    glGenRenderbuffers( 1, &_water_render_buffer );
    glBindRenderbuffer( GL_RENDERBUFFER, _water_render_buffer );
    glRenderbufferStorage( GL_RENDERBUFFER, GL_DEPTH_COMPONENT, width, height );
    glFramebufferRenderbuffer( GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _water_render_buffer );
    
    
    glBindTexture( GL_TEXTURE_2D, _water_textures[ 1 ] );
    glTexImage2D( GL_TEXTURE_2D, 0, GL_RGB, width * .75, height * .75, 0,
                 GL_RGB, GL_UNSIGNED_BYTE, nullptr );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
    glBindFramebuffer( GL_FRAMEBUFFER, _water_fbo[ 1 ] );
    glFramebufferTexture( GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, _water_textures[ 1 ], 0 );
    
    glBindTexture( GL_TEXTURE_2D, _water_textures[ 2 ] );
    glTexImage2D( GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT32, width * .75, height * .75, 0,
                 GL_DEPTH_COMPONENT, GL_FLOAT, nullptr );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
    glBindFramebuffer( GL_FRAMEBUFFER, _water_fbo[ 1 ] );
    glFramebufferTexture( GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, _water_textures[ 2 ], 0 );
    
    
    //glBindTexture( GL_TEXTURE_2D, _water_textures[ 3 ] );
    //glTexImage2D( GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT32, width, height, 0,
    //              GL_DEPTH_COMPONENT, GL_FLOAT, nullptr );
    //glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
    //glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
    //glBindFramebuffer( GL_FRAMEBUFFER, _water_fbo[ 1 ] );
    //glFramebufferTexture( GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, _water_textures[ 3 ], 0
    
    glBindTexture( GL_TEXTURE_2D, 0 );
    glBindFramebuffer( GL_FRAMEBUFFER, 0 );
    glClearColor( 1.0, 1.0, 1.0, 1.0 );
    
    //glMatrixMode( GL_PROJECTION );
    //gluPerspective( 75, _width / _height, 1, 3000 );
    glViewport( 0, 0, width, height );
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
    
    const vec4 waterPlane( 0, 1, 0, 0 );
    
    glUniform4fv( _program->find_uniform( "uWaterPlane" ), 1, &waterPlane[0] );
    
    mat4 waterModel;
    
    _water_program.bind();
    glUniform3fv( _water_program.find_uniform( "uSunPosition" ), 1,
                 &sunPosition[0] );
    glUniform3fv( _water_program.find_uniform( "uSunColor" ), 1,
                 &specularComponent[0] );
    glUniform1i( _water_program.find_uniform( "uTextureRefle" ), 0 );
    glUniform1i( _water_program.find_uniform( "uTextureRefra" ), 1 );
    glUniform1i( _water_program.find_uniform( "uMapDepth" ), 2 );
    glUniform1i( _water_program.find_uniform( "uMapDuDv" ), 3 );
    glUniform1i( _water_program.find_uniform( "uMapNormal" ), 4 );
    
    glUniform4f( _water_program.find_uniform( "uColor" ), 0, 0.1, 1, 0.1 );
    glUniformMatrix4fv( _water_program.find_uniform( "uModelMatrix" ),
                       1, GL_FALSE, &waterModel[ 0 ][ 0 ] );
    
#ifndef DEMO
    size_t railsize = _rail.rail.size();
    _eyepos = _rail.rail[ _railidx % railsize ];
    _eyelook = _rail.rail[ (_railidx + 1) % railsize ];
    _eyelook2 = _rail.rail[ (_railidx + 3) % railsize ];
#endif
}



void Game::render()
{
    _currTime += 0.01;
    const double time = _currTime - _startTime;
    
    glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
    
    glDisable( GL_CLIP_DISTANCE0 );
    glDisable( GL_CLIP_DISTANCE1 );
    
    glEnable( GL_DEPTH_TEST );
    glEnable( GL_CULL_FACE );
    
    glCullFace( GL_BACK );
    
#ifdef DEMO
    float eyedist = 5;
    //vec3 eyepos( eyedist, eyedist + (eyedist * 0.8 * sin( time )), eyedist );
    vec3 eyepos(
                eyedist * sin( time ),
                0.1 + eyedist / 4 + eyedist / 4 * sin( time / 3 ),
                eyedist * cos( time )
                );
    vec3 eyelook;
#else
    
    size_t railsize = _rail.rail.size();
    
    _eyelook = _rail.rail[ (_railidx + 1) % railsize ];
    _eyelook2 = _rail.rail[ (_railidx + 3) % railsize ];
    
    vec3 eyepos = _rail.rail[ _railidx ];
    if ( eyepos.x != _eyepos.x || eyepos.y != _eyepos.y || eyepos.z != _eyepos.z )
    {
        _eyepos = eyepos;
        _time = time;
    }
    
    float a = (time - _time) / length( _eyelook - _eyelook2 ) * 8;
    vec3 eyelook = glm::mix( _eyelook, _eyelook2, a );
    
    a = (time - _time) / length( _eyepos - _eyelook ) * 8;
    eyepos = glm::mix( _eyepos, _eyelook, a );
    if ( a > 1 ) {
        _railidx += 2;
        _railidx %= railsize;
    }
    eyepos.y -= 0.5;
    eyelook.y -= 0.5;
#endif
    
    
    const mat4 view = lookAt( eyepos, eyelook, vec3( 0, 1, 0 ) );
    
    const float aspectRatio = _width / _height;
    const mat4 proj = perspective< float >( radians( 60.0f ), aspectRatio, 0.1, 1000 );
    
    _program->bind();
    glUniformMatrix4fv( _program->find_uniform( "uProjMatrix" ),
                       1, GL_FALSE, &proj[ 0 ][ 0 ] );
    glUniformMatrix4fv( _program->find_uniform( "uViewMatrix" ),
                       1, GL_FALSE, &view[ 0 ][ 0 ] );
    
    float waveFactor = (time / 10);
    _water_program.bind();
    glUniform1f( _water_program.find_uniform( "uDuDvFactor" ), waveFactor );
    glUniform3fv( _water_program.find_uniform( "uEyePosition" ), 1, &eyepos[0] );
    glUniformMatrix4fv( _water_program.find_uniform( "uViewMatrix" ),
                       1, GL_FALSE, &view[ 0 ][ 0 ] );
    glUniformMatrix4fv( _water_program.find_uniform( "uProjMatrix" ),
                       1, GL_FALSE, &proj[ 0 ][ 0 ] );
    
    
    glBindTexture( GL_TEXTURE_2D, 0 );
    glBindFramebuffer( GL_FRAMEBUFFER, 0 );
    glViewport( 0, 0, (int) _width, (int) _height );
    
    for ( int i = 0; i < _entities.size(); i++ )
    {
#if USE_QUATERNIONS
        _entities[ i ].orientation *= _entities[ i ].orientation;
#else
        _entities[ i ].rotation[ i % 3 ] += 0.03f;
#endif
    }
    
    
    glDisable( GL_CLIP_DISTANCE0 );
    glDisable( GL_CLIP_DISTANCE1 );
    
    
    // Render refLEction.
    glBindTexture( GL_TEXTURE_2D, 0 );
    glBindFramebuffer( GL_FRAMEBUFFER, _water_fbo[ 0 ] );
    glViewport( 0, 0, (int) _width/2, (int) _height/2 );
    glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
    glEnable( GL_CLIP_DISTANCE0 );
    eyepos.y = -eyepos.y;
    eyelook.y = -eyelook.y;
    draw_scene( lookAt( eyepos, eyelook, vec3( 0, 1, 0 ) ), proj );
    glDisable( GL_CLIP_DISTANCE0 );
    glBindTexture( GL_TEXTURE_2D, _water_textures[ 0 ] );
    glBindFramebuffer( GL_FRAMEBUFFER, 0 );
    
    
    // Render refRAction.
    glBindTexture( GL_TEXTURE_2D, 0 );
    glBindFramebuffer( GL_FRAMEBUFFER, _water_fbo[ 1 ] );
    glViewport( 0, 0, (int) (_width * .75), (int) (_height * .75) );
    glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
    glEnable( GL_CLIP_DISTANCE1 );
    draw_scene( view, proj );
    glDisable( GL_CLIP_DISTANCE1 );
    glBindTexture( GL_TEXTURE_2D, _water_textures[ 1 ] );
    glBindFramebuffer( GL_FRAMEBUFFER, 0 );
    
    
    // Draw our scene.
    glEnable( GL_CULL_FACE );
    glBindFramebuffer( GL_FRAMEBUFFER, 0 );
    glViewport( 0, 0, (int) _width, (int) _height );
    //draw_scene( view, proj );
    _skybox_program.bind();
    glUniformMatrix4fv( _skybox_program.find_uniform( "uViewMatrix" ),
                       1, GL_FALSE, &view[ 0 ][ 0 ] );
    glUniformMatrix4fv( _skybox_program.find_uniform( "uProjMatrix" ),
                       1, GL_FALSE, &proj[ 0 ][ 0 ] );
    
    glUniform1i( _skybox_program.find_uniform( "uTexture" ), 0 );
    glActiveTexture( GL_TEXTURE0 );
    glBindTexture( GL_TEXTURE_CUBE_MAP, _skybox_texture );
    _skybox_buffer.draw( GL_TRIANGLES, 0, 36 );
    
    _program->bind();
    glUniformMatrix4fv( _program->find_uniform( "uViewMatrix" ),
                       1, GL_FALSE, &view[ 0 ][ 0 ] );
    glUniformMatrix4fv( _program->find_uniform( "uProjMatrix" ),
                       1, GL_FALSE, &proj[ 0 ][ 0 ] );
    glUniform4f( _program->find_uniform( "uColor" ), 1, 1, 1, 0 );
    
    _model.render( mat4(), view, proj );
    
    for ( Entity& entity : _entities )
        entity.render( view, proj );
    
#ifndef DEMO
    glUniform4f( _program->find_uniform( "uColor" ), 1, 1, 1, 0 );
    _level.render( translate( mat4(), vec3( 0, -0.1, 0 ) ), view, proj );
#endif
    
    
    // Draw water.
    _water_program.bind();
    //glDisable( GL_CULL_FACE );
    glActiveTexture( GL_TEXTURE0 );
    glBindTexture( GL_TEXTURE_2D, _water_textures[ 0 ] );
    glActiveTexture( GL_TEXTURE1 );
    glBindTexture( GL_TEXTURE_2D, _water_textures[ 1 ] );
    glActiveTexture( GL_TEXTURE2 );
    glBindTexture( GL_TEXTURE_2D, _water_textures[ 2 ] );
    glActiveTexture( GL_TEXTURE3 );
    glBindTexture( GL_TEXTURE_2D, _water_dudv.glHandle );
    glActiveTexture( GL_TEXTURE4 );
    glBindTexture( GL_TEXTURE_2D, _water_normal.glHandle );
    
    //glEnable( GL_BLEND );
    //glDisable( GL_DEPTH_TEST );
    _water_quad.draw( GL_QUADS, 0, 4 );
    //glEnable( GL_DEPTH_TEST );
    //glDisable( GL_BLEND );
    //glEnable( GL_CULL_FACE );
    
#ifndef DEMO
    glEnable( GL_BLEND );
    _enemies.render( translate( mat4(), vec3( 0, -0.1, 0 ) ), view, proj );
    glDisable( GL_BLEND );
#endif
    
    //#ifndef DEMO
    //_program->bind();
    //glUniform4f( _program->find_uniform( "uColor" ), 1, 1, 1, 0 );
    //glEnable( GL_BLEND );
    //_level.render( translate( mat4(), vec3( 0, 1, 0 ) ), view, proj );
    //glDisable( GL_BLEND );
    //#endif
}

void Game::update()
{
}

void Game::draw_scene( glm::mat4 view, glm::mat4 proj )
{
    _skybox_program.bind();
    glUniformMatrix4fv( _skybox_program.find_uniform( "uViewMatrix" ),
                       1, GL_FALSE, &view[ 0 ][ 0 ] );
    glUniformMatrix4fv( _skybox_program.find_uniform( "uProjMatrix" ),
                       1, GL_FALSE, &proj[ 0 ][ 0 ] );
    
    glUniform1i( _skybox_program.find_uniform( "uTexture" ), 0 );
    glActiveTexture( GL_TEXTURE0 );
    glBindTexture( GL_TEXTURE_CUBE_MAP, _skybox_texture );
    _skybox_buffer.draw( GL_TRIANGLES, 0, 36 );
    
    _program->bind();
    glUniformMatrix4fv( _program->find_uniform( "uViewMatrix" ),
                       1, GL_FALSE, &view[ 0 ][ 0 ] );
    glUniformMatrix4fv( _program->find_uniform( "uProjMatrix" ),
                       1, GL_FALSE, &proj[ 0 ][ 0 ] );
    glUniform4f( _program->find_uniform( "uColor" ), 1, 1, 1, 0 );
    
    _model.render( mat4(), view, proj );
    
    for ( Entity& entity : _entities )
        entity.render( view, proj );
    
#ifndef DEMO
    glUniform4f( _program->find_uniform( "uColor" ), 1, 1, 1, 0 );
    _level.render( translate( mat4(), vec3( 0, -0.1, 0 ) ), view, proj );
    glEnable( GL_BLEND );
    _enemies.render( translate( mat4(), vec3( 0, -0.1, 0 ) ), view, proj );
    glDisable( GL_BLEND );
#endif
}
