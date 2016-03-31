#pragma once

#include "glhelp.h"
#include "ObjMesh.h"

#include <vector>
#include <memory>



class Model
{
public:

    explicit Model( const ObjMesh& mesh, GLProgram::ptr_t program );// , std::string vert, std::string frag );

    //void render() const;
    void render( glm::mat4 model,
                 glm::mat4 view,
                 glm::mat4 proj,
                 GLenum    mode = GL_TRIANGLES ) const;

    ObjMesh             _mesh;
    GLVertexBuffer      _buffer;
    GLProgram::ptr_t    _program;
};

