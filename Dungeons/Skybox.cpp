//
//  Skybox.cpp
//  Dungeons
//
//  Created by Andrew Meckling on 2016-04-09.
//  Copyright © 2016 Andrew Meckling. All rights reserved.
//

#include "Skybox.hpp"
#include "SOIL.h"
#include "ios_path.h"

using glm::vec3;
using glm::vec4;
using glm::mat4;

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

const float AU = 1.496e+11f;

Skybox::Skybox( std::string name, vec3 sunDirection, vec4 sunColor )
    : _cubemap( SOIL_load_OGL_cubemap(
        ios_path( "skybox/" + name + "_ft.tga" ),
        ios_path( "skybox/" + name + "_bk.tga" ),
        ios_path( "skybox/" + name + "_up.tga" ),
        ios_path( "skybox/" + name + "_dn.tga" ),
        ios_path( "skybox/" + name + "_rt.tga" ),
        ios_path( "skybox/" + name + "_lf.tga" ),
        SOIL_LOAD_AUTO,
        SOIL_CREATE_NEW_ID,
        SOIL_FLAG_MIPMAPS | SOIL_FLAG_NTSC_SAFE_RGB | SOIL_FLAG_COMPRESS_TO_DXT ) )
    , _program( ios_path( "Skybox.vs" ), ios_path( "Skybox.fs" ), "aPosition" )
    , _vertBuffer( SKYBOX_VERTICES, 36, gl_enums::STATIC_DRAW,
                   _program.make_vert_attribute< vec3 >( "aPosition" ) )
    , sunPosition( glm::normalize( sunDirection ) * AU )
    , sunColor( sunColor )
{
    glBindTexture( GL_TEXTURE_CUBE_MAP, _cubemap );
    glTexParameteri( GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE );
    glTexParameteri( GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE );
    glBindTexture( GL_TEXTURE_CUBE_MAP, 0 );
}

void Skybox::render( mat4 view, mat4 proj ) const
{
    _program.bind();
    glUniformMatrix4fv( _program.find_uniform( "uViewMatrix" ), 1, GL_FALSE, &view[ 0 ][ 0 ] );
    glUniformMatrix4fv( _program.find_uniform( "uProjMatrix" ), 1, GL_FALSE, &proj[ 0 ][ 0 ] );
    
    glUniform1i( _program.find_uniform( "uTexture" ), 0 );
    glActiveTexture( GL_TEXTURE0 );
    glBindTexture( GL_TEXTURE_CUBE_MAP, _cubemap );
    
    _vertBuffer.draw( GL_TRIANGLES, 0, 36 );
}











