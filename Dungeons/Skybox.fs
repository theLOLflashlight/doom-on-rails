#version 300 es
precision highp float;

in          vec3            vCubeCoord;

uniform     samplerCube     uCube;

out         vec4            out_Color;

void main()
{
    out_Color = texture( uCube, vCubeCoord );
}