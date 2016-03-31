#pragma once

#include "Model.h"

#include "glm/glm.hpp"

#ifndef USE_QUATERNIONS
#define USE_QUATERNIONS 0
#endif

struct Entity
{
    const Model*    model;
    glm::vec3       position;
#if USE_QUATERNIONS
    glm::vec4       orientation;
#else
    glm::vec3       rotation;
#endif
    glm::vec3       scale;
    glm::vec4       color;

    Entity
    (
        const Model*    model,
        glm::vec3       position        = {},
#if USE_QUATERNIONS
        glm::vec4       orientation     = { 0, 0, 0, 1 },
#else
        glm::vec3       rotation        = {},
#endif
        glm::vec3       scale           = { 1, 1, 1 },
        glm::vec4       color           = { 1, 1, 1, 0 }
    );

    void render( glm::mat4 view, glm::mat4 proj ) const;
};

