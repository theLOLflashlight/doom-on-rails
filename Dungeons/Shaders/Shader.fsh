//
//  Shader.fsh
//  Dungeons
//
//  Created by Andrew Meckling on 2016-03-22.
//  Copyright © 2016 Andrew Meckling. All rights reserved.
//
#version 300 es
precision highp float;

in lowp vec4 colorVarying;

out vec4 out_FragColor;

void main()
{
    out_FragColor = colorVarying;
}
