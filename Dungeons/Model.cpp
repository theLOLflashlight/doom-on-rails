#include "Model.h"
#include "glm/glm.hpp"

using namespace gl_enums::usage;
using std::shared_ptr;
using std::make_shared;
using glm::vec3;
using glm::vec2;

Model::Model( const ObjMesh& mesh, GLProgram* program )
    : Renderable( program )
    , _mesh( mesh )
    , _buffer( _mesh.data(), static_cast< GLsizei >( _mesh.size() ), STATIC_DRAW,
        _program->make_vert_attribute< vec3 >( "aPosition" ),
        _program->make_vert_attribute< vec3 >( "aNormal" ),
        _program->make_vert_attribute< vec2 >( "aTexCoord" ) )
{
}

void Model::render( glm::mat4 model ) const
{
    using namespace glm;
    
    _program->bind();
    glUniformMatrix4fv( _program->find_uniform( "uModelMatrix" ), 1, GL_FALSE, (float*)&model );

    glActiveTexture( GL_TEXTURE0 );
    for ( auto texture : _mesh.textures )
    {
        auto mtl = texture.material;
        if ( mtl->map_Kd != nullptr )
        {
            mtl->map_Kd->bind();
            _buffer.draw( mode, texture.offset, texture.count );
        }
    }
}

struct SpriteVertex
{
    vec3 position;
    vec2 texCoord;
};

const float SZ = 0.5f;

const SpriteVertex SPRITE_VERTICES[] = {
    { vec3( -SZ, -SZ, 0 ), vec2( 0, 0 ) },
    { vec3( -SZ,  SZ, 0 ), vec2( 0, 1 ) },
    { vec3(  SZ,  SZ, 0 ), vec2( 1, 1 ) },
    
    { vec3(  SZ,  SZ, 0 ), vec2( 1, 1 ) },
    { vec3(  SZ, -SZ, 0 ), vec2( 1, 0 ) },
    { vec3( -SZ, -SZ, 0 ), vec2( 0, 0 ) }
};

Sprite::Sprite( std::string texture, GLProgram* program )
    : Renderable( program )
    , _texture( texture )
    , _buffer( SPRITE_VERTICES, 6, STATIC_DRAW,
               _program->make_vert_attribute< vec3 >( "aPosition" ),
               _program->make_vert_attribute< vec2 >( "aTexCoord" ) )
{
    _program->bind();
    glUniform1i( _program->find_uniform( "uTexture" ), 0 );
    glUseProgram( 0 );
}

void Sprite::render( glm::mat4 model ) const
{
    _program->bind();
    glUniformMatrix4fv( _program->find_uniform( "uModelMatrix" ), 1, GL_FALSE, (float*)&model );
    glUniform2f( _program->find_uniform( "uSpriteSize" ), width, height );
    glUniform3fv( _program->find_uniform( "uSpriteAxis" ), 1, &spriteAxis[0] );
    
    
    glActiveTexture( GL_TEXTURE0 );
    _texture.bind();
    
    glDisable( GL_CULL_FACE );
    _buffer.draw( GL_TRIANGLES, 0, 6 );
    glEnable( GL_CULL_FACE );
}























