// Andrew
#version 300 es
precision highp float;

in          vec2        vTexCoord;

uniform     sampler2D   uTexture;
uniform     vec4        uColor;

uniform     vec4        uAmbientColor;
uniform     vec4        uDiffuseColor;

out         vec4        out_Color;

const       float       FIRE_STRENGTH       = 0.02;

void main()
{
    vec4 Ka = uAmbientColor;
    vec4 Kd = uDiffuseColor;
    
    out_Color = (Ka + Kd) * texture( uTexture, vTexCoord );
    out_Color.rgb = mix( out_Color.rgb, uColor.rgb, uColor.a );
}