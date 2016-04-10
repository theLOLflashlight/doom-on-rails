#pragma once

#include "glhelp.h"
#include "ObjMesh.h"

#include <vector>
#include <memory>


struct Sprite
{
    GLTexture::ptr_t    _texture;
    int                 _width;
    int                 _height;
    
    void render( glm::mat4 model,
                 glm::mat4 view,
                 glm::mat4 proj ) const;

};

struct Model
{
    Model( const ObjMesh& mesh, GLProgram* program );// , std::string vert, std::string frag );

    //void render() const;
    void render( glm::mat4 model,
                 glm::mat4 view,
                 glm::mat4 proj,
                 GLenum    mode = GL_TRIANGLES ) const;

    ObjMesh             _mesh;
    GLVertexBuffer      _buffer;
    GLProgram*          _program;
};

