#pragma once

#include "glhelp.h"
#include "ObjMesh.h"

#include <vector>
#include <memory>
#include <string>


struct Sprite
{
    GLTexture      _texture;
    GLVertexBuffer _buffer;
    int          _width = 1;
    int          _height = 1;
    
    Sprite( std::string texture, GLProgram* program );
    
    void render() const;

};

struct Model
{
    Model( const ObjMesh& mesh, GLProgram* program );

    //void render() const;
    void render( glm::mat4 model,
                 GLenum    mode = GL_TRIANGLES ) const;

    ObjMesh             _mesh;
    GLVertexBuffer      _buffer;
    GLProgram*          _program;
};

