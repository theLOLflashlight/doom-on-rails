//
//  Skybox.hpp
//  Dungeons
//
//  Created by Andrew Meckling on 2016-04-09.
//  Copyright © 2016 Andrew Meckling. All rights reserved.
//

#ifndef Skybox_hpp
#define Skybox_hpp

#include <string>
#include "GLHandle.h"
#include "GLProgram.h"
#include "glhelp.h"

struct Skybox
{
    GLHandle        _cubemap;
    GLProgram       _program;
    GLVertexBuffer  _vertBuffer;
    
    glm::vec3       sunPosition;
    glm::vec4       sunColor;
    
    Skybox( std::string name, glm::vec3 sunPosition, glm::vec4 sunColor );
    
    void render( glm::mat4 view, glm::mat4 proj ) const;
};

#endif /* Skybox_hpp */
