//
//  Water.cpp
//  Dungeons
//
//  Created by Andrew Meckling on 2016-04-09.
//  Copyright © 2016 Andrew Meckling. All rights reserved.
//

#include "Water.hpp"
#include "ios_path.h"

using glm::vec3;
using glm::vec4;
using glm::mat4;

const float WATER_SIZE = 1000;

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


Water::Water( vec4 _color, float width, float height )
    : color( _color )
    , _waterDudv( ios_path( "water/water_dudv.png" ) )
    , _waterNormal( ios_path( "water/water_normal.png" ) )
    , _program( ios_path( "WaterShader.vs" ), ios_path( "WaterShader.fs" ), "aPosition" )
    , _vertBuffer( WATER_VERTICES, 6, gl_enums::STATIC_DRAW,
                   _program.make_vert_attribute< vec3 >( "aPosition" ) )
{
    GLenum status;
    
    // REFLECT
    
    // COLOR TEXTURE
    glGenTextures( 1, &_reflectTexture );
    glBindTexture( GL_TEXTURE_2D, _reflectTexture );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
    glTexImage2D( GL_TEXTURE_2D, 0, GL_RGB, width/2, height/2, 0, GL_RGB, GL_UNSIGNED_BYTE, nullptr );
    glBindTexture( GL_TEXTURE_2D, 0 );
    
    // DEPTH BUFFER
    glGenRenderbuffers( 1, &_reflectRenderBuffer );
    glBindRenderbuffer( GL_RENDERBUFFER, _reflectRenderBuffer );
    glRenderbufferStorage( GL_RENDERBUFFER, GL_DEPTH_COMPONENT32F, width, height );
    glBindRenderbuffer( GL_RENDERBUFFER, 0 );
    
    // FRAME BUFFER
    glGenFramebuffers( 1, &_reflectFbo );
    glBindFramebuffer( GL_FRAMEBUFFER, _reflectFbo );
    glFramebufferTexture2D( GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _reflectTexture, 0 );
    
    glFramebufferRenderbuffer( GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _reflectRenderBuffer );
    
    status = glCheckFramebufferStatus( GL_FRAMEBUFFER );
    glBindFramebuffer( GL_FRAMEBUFFER, 0 );
    if ( status != GL_FRAMEBUFFER_COMPLETE )
        throw status;
    
    // REFRACT
    
    // COLOR TEXTURE
    glGenTextures( 1, &_refractTexture );
    glBindTexture( GL_TEXTURE_2D, _refractTexture );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
    glTexImage2D( GL_TEXTURE_2D, 0, GL_RGB, width * .75, height * .75, 0, GL_RGB, GL_UNSIGNED_BYTE, nullptr );
    glBindTexture( GL_TEXTURE_2D, 0 );
    
    // DEPTH TEXTURE
    glGenTextures( 1, &_depthTexture );
    glBindTexture( GL_TEXTURE_2D, _depthTexture );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
    glTexImage2D( GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT32F, width * .75, height * .75, 0, GL_DEPTH_COMPONENT, GL_FLOAT, nullptr );
    glBindTexture( GL_TEXTURE_2D, 0 );
    
    // DEPTH BUFFER
    glGenRenderbuffers( 1, &_refractRenderBuffer );
    glBindRenderbuffer( GL_RENDERBUFFER, _refractRenderBuffer );
    glRenderbufferStorage( GL_RENDERBUFFER, GL_DEPTH_COMPONENT32F, width, height );
    glBindRenderbuffer( GL_RENDERBUFFER, 0 );
    
    // FRAME BUFFER
    glGenFramebuffers( 1, &_refractFbo );
    glBindFramebuffer( GL_FRAMEBUFFER, _refractFbo );
    glFramebufferTexture2D( GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _refractTexture, 0 );
    glFramebufferTexture2D( GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_TEXTURE_2D, _depthTexture, 0 );
    
    glFramebufferRenderbuffer( GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _refractRenderBuffer );
    
    status = glCheckFramebufferStatus( GL_FRAMEBUFFER );
    glBindFramebuffer( GL_FRAMEBUFFER, 0 );
    if ( status != GL_FRAMEBUFFER_COMPLETE )
        throw status;
    
    _program.bind();
    glUniform1i( _program.find_uniform( "uTextureRefle" ), 0 );
    glUniform1i( _program.find_uniform( "uTextureRefra" ), 1 );
    glUniform1i( _program.find_uniform( "uMapDepth" ), 2 );
    glUniform1i( _program.find_uniform( "uMapDuDv" ), 3 );
    glUniform1i( _program.find_uniform( "uMapNormal" ), 4 );
    
    glUniform4fv( _program.find_uniform( "uColor" ), 1, &color[0] );/*           */mat4 waterModel;
    glUniformMatrix4fv( _program.find_uniform( "uModelMatrix" ), 1, GL_FALSE, (float*) &waterModel );
    
    glUseProgram( 0 );
}

void Water::setSun( vec3 position, vec4 color )
{
    _program.bind();
    glUniform3fv( _program.find_uniform( "uSunPosition" ), 1, &position[0] );
    glUniform3fv( _program.find_uniform( "uSunColor" ), 1, &color[0] );
    
    glUseProgram( 0 );
}

void Water::update( float waveFactor, vec3 eyepos )
{
    _program.bind();
    glUniform1f( _program.find_uniform( "uDuDvFactor" ), waveFactor );
    glUniform3fv( _program.find_uniform( "uEyePosition" ), 1, &eyepos[0] );
    
    glUseProgram( 0 );
}

void Water::bindReflection( GLProgram* program, float width, float height ) const
{
    glBindFramebuffer( GL_FRAMEBUFFER, _reflectFbo );
    glViewport( 0, 0, (int) width/2, (int) height/2 );
    glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
    
    program->bind();
    glUniform4f( program->find_uniform( "uWaterPlane" ), 0, 1, 0, 0 );
    glUseProgram( 0 );
}

void Water::bindRefraction( GLProgram* program, float width, float height ) const
{
    glBindFramebuffer( GL_FRAMEBUFFER, _refractFbo );
    glViewport( 0, 0, (int) (width * .75), (int) (height * .75) );
    glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
    
    program->bind();
    glUniform4f( program->find_uniform( "uWaterPlane" ), 0, -1, 0, 0 );
    glUseProgram( 0 );
}

void Water::render( mat4 view, mat4 proj ) const
{
    _program.bind();
    //glDisable( GL_CULL_FACE );
    glActiveTexture( GL_TEXTURE0 );
    glBindTexture( GL_TEXTURE_2D, _reflectTexture );
    
    glActiveTexture( GL_TEXTURE1 );
    glBindTexture( GL_TEXTURE_2D, _refractTexture );
    
    glActiveTexture( GL_TEXTURE2 );
    glBindTexture( GL_TEXTURE_2D, _depthTexture );
    
    glActiveTexture( GL_TEXTURE3 );
    glBindTexture( GL_TEXTURE_2D, _waterDudv.glHandle );
    
    glActiveTexture( GL_TEXTURE4 );
    glBindTexture( GL_TEXTURE_2D, _waterNormal.glHandle );
    
    
    glUniformMatrix4fv( _program.find_uniform( "uViewMatrix" ), 1, GL_FALSE, &view[ 0 ][ 0 ] );
    glUniformMatrix4fv( _program.find_uniform( "uProjMatrix" ), 1, GL_FALSE, &proj[ 0 ][ 0 ] );
    
    _vertBuffer.draw( GL_TRIANGLES, 0, 6 );
    
    glUseProgram( 0 );
}









