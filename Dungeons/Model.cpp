#include "Model.h"
#include "glm/glm.hpp"

using namespace gl_enums::usage;
using std::shared_ptr;
using std::make_shared;
using glm::vec3;
using glm::vec2;

Model::Model( const ObjMesh& mesh, GLProgram::ptr_t program )
    : _mesh( mesh )
    , _program( program )
    , _buffer( _mesh.data(), _mesh.size(), STATIC_DRAW,
        program->make_vert_attribute< vec3 >( "aPosition" ),
        program->make_vert_attribute< vec3 >( "aNormal" ),
        program->make_vert_attribute< vec2 >( "aTexCoord" ) )
{
}

void Model::render
(
    glm::mat4 model,
    glm::mat4 view,
    glm::mat4 proj,
    GLenum    mode
) const
{
    using namespace glm;
    
    _program->bind();
    glUniformMatrix4fv( _program->find_uniform( "uModelMatrix" ), 1, GL_FALSE, &model[ 0 ][ 0 ] );
    glUniformMatrix4fv( _program->find_uniform( "uViewMatrix" ), 1, GL_FALSE, &view[ 0 ][ 0 ] );
    glUniformMatrix4fv( _program->find_uniform( "uProjMatrix" ), 1, GL_FALSE, &proj[ 0 ][ 0 ] );

    //glUniform4f( _program->find_uniform( "uColor" ), 0, 0, 1, 1 );
    glUniform1i( _program->find_uniform( "uTexture" ), 0 );
    //glUniform1i( _program->find_uniform( "uDecal" ), 1 );

    glActiveTexture( GL_TEXTURE0 );
    for ( auto texture : _mesh.textures )
    {
        //glUniform4f( _program->find_uniform( "uKa" ), mtl.Ka.r, mtl.Ka.g, mtl.Ka.b, 1 );
        //glUniform4f( _program->find_uniform( "uKd" ), mtl.Kd.r, mtl.Kd.g, mtl.Kd.b, 1 );
        //glUniform4f( _program->find_uniform( "uKs" ), mtl.Ks.r, mtl.Ks.g, mtl.Ks.b, 1 );
        //glUniform1f( _program->find_uniform( "uNs" ), mtl.Ns );
        
        auto mtl = texture.material;
        if ( mtl->map_Kd != nullptr )
        {
            mtl->map_Kd->bind();
            _buffer.draw( mode, texture.offset, texture.count );
        }
        else
        {
            ;// no texture
        }
    }
}

void Sprite::render(glm::mat4 model, glm::mat4 view, glm::mat4 proj) const
{
    /*glBegin(GL_TRIANGLE_FAN);
    glVertex3f(10, -12, 0);
    glVertex3f(10, 12, 0);
    glVertex3f(-10, 12, 0);
    glVertex3f(-10, -12, 0);
    glEnd();*/
}























