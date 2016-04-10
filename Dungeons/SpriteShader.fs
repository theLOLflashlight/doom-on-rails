#version 300 es
precision highp float;

in          vec2        vTexCoord;

uniform     sampler2D   uTexture;
uniform     vec4        uColor;

uniform     vec4        uAmbientColor;
uniform     vec4        uDiffuseColor;

out         vec4        out_Color;

void main()
{
    vec4 Ka = uAmbientColor;
    vec4 Kd = uDiffuseColor;
    
    out_Color = (Ka + Kd) * texture( uTexture, vTexCoord );
    out_Color = mix( out_Color, vec4( uColor.rgb, 1 ), uColor.a );
}