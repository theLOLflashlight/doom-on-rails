//
//  Water.hpp
//  Dungeons
//
//  Created by Andrew Meckling on 2016-04-09.
//  Copyright © 2016 Andrew Meckling. All rights reserved.
//

#ifndef Water_hpp
#define Water_hpp

#include "glhelp.h"

struct Water
{
    glm::vec4       color;
    
    GLTexture       _waterDudv, _waterNormal;
    GLProgram       _program;
    GLVertexBuffer  _vertBuffer;
    
    GLHandle        _reflectTexture, _refractTexture, _depthTexture;
    GLHandle        _reflectFbo, _refractFbo;
    
    GLHandle        _reflectRenderBuffer, _refractRenderBuffer;
    
    explicit Water( glm::vec4 color, float width, float height );
    
    void setSun( glm::vec3 position, glm::vec4 color );
    
    void update( float waveFactor, glm::vec3 eyepos );
    
    void bindReflection( GLProgram* program, float width, float height ) const;
    void bindRefraction( GLProgram* program, float width, float height ) const;
    
    void render( glm::mat4 view, glm::mat4 proj ) const;
};

#endif /* Water_hpp */
