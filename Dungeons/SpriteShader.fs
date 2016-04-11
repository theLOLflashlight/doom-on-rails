#version 300 es
precision highp float;

in          vec2        vTexCoord;

uniform     sampler2D   uTexture;
//uniform     sampler2D   uMapDuDv;
uniform     vec4        uColor;

//uniform     float       uDuDvFactor;

uniform     vec4        uAmbientColor;
uniform     vec4        uDiffuseColor;

out         vec4        out_Color;

const       float       FIRE_STRENGTH       = 0.02;

void main()
{
    vec4 Ka = uAmbientColor;
    vec4 Kd = uDiffuseColor;
    
    /*vec2 distor = texture( uMapDuDv, vec2( vTexCoord.x + uDuDvFactor, vTexCoord.y ) ).rg * 0.1;
    distor = vTexCoord + vec2( distor.x, distor.y + uDuDvFactor );
    distor = (texture( uMapDuDv, distor ).rg * 2.0 - 1.0) * FIRE_STRENGTH;*/
    
    out_Color = (Ka + Kd) * texture( uTexture, vTexCoord ) * 2.0;
    out_Color = mix( out_Color, vec4( uColor.rgb, 1 ), uColor.a );
}