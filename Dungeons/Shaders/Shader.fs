//
//  Shader.fsh
//  Dungeons
//
//  Created by Andrew Meckling on 2016-03-22.
//  Copyright © 2016 Andrew Meckling. All rights reserved.
//
#version 300 es
precision highp float;

uniform     vec4        uColor;

out vec4 out_Color;

void main()
{
    out_Color = uColor;
}
