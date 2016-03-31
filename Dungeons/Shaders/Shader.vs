//
//  Shader.vsh
//  Dungeons
//
//  Created by Andrew Meckling on 2016-03-22.
//  Copyright © 2016 Andrew Meckling. All rights reserved.
//
#version 300 es

in vec3 aPosition;

uniform mat4 uViewMatrix;
uniform mat4 uProjMatrix;

void main()
{
    gl_Position = uProjMatrix * uViewMatrix * vec4( aPosition, 1.0 );
}
