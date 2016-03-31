#pragma once

#include "GLTexture.h"

#include "glm/glm.hpp"

enum class IlluminationMode : GLbyte
{
    COLOR_ON_AMBIENT_OFF = 0,
    COLOR_ON_AMBIENT_ON,
    HIGHLIGHT_ON,
    REFLECTION_ON_RAYTRACE_ON,
    TRANS_GLASS_ON_REFL_RAYTRACE_ON,
    //...
};

struct Material
{
    glm::vec3   Ka = {};
    glm::vec3   Kd = {};
    glm::vec3   Ks = {};
    GLfloat     Ns = 0;
    GLfloat     d = 1;
    //IlluminationMode illum
    GLTexture::ptr_t map_Ka = {};
    GLTexture::ptr_t map_Kd = {};
    GLTexture::ptr_t map_Ks = {};
    GLTexture::ptr_t map_Ns = {};
    GLTexture::ptr_t map_d = {};
    GLTexture::ptr_t map_bump = {};
    char Name[32] = { 0 };
    const char _end = '\0';
};

