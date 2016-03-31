#pragma once

#include "glm/glm.hpp"

struct ObjVertex
{
    glm::vec3 aPosition;
    glm::vec3 aNormal;
    glm::vec2 aTexCoord;

    ObjVertex() = default;

    ObjVertex( glm::vec3 position,
            glm::vec3 normal,
            glm::vec2 texcoord )
        : aPosition( position )
        , aNormal( normal )
        , aTexCoord( texcoord )
    {
    }
};

