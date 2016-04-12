#version 300 es
precision highp float;

in          vec2        vTexCoord;

uniform     sampler2D   uTexture;
uniform     sampler2D   uMapDuDv;
uniform     vec4        uColor;

uniform     float       uDuDvFactor;

out         vec4        out_Color;

const       float       FIRE_STRENGTH       = 0.35;
const       float       FIRE_BRIGHTNESS     = 1.5;

void main()
{
    vec2 texCoord = vTexCoord;
    
    vec2 distor = texture( uMapDuDv, vec2( vTexCoord.x + uDuDvFactor, vTexCoord.y ) ).rg * 0.1;
    distor = vTexCoord + vec2( distor.x, distor.y - uDuDvFactor );
    distor = (texture( uMapDuDv, distor / 2.0 ).rg * 2.0 - 1.0) * FIRE_STRENGTH;
    
    texCoord += distor;
    texCoord = clamp( texCoord, 0.001, 0.999 );
    
    out_Color = texture( uTexture, texCoord ) * FIRE_BRIGHTNESS;
    out_Color.rgb = mix( out_Color.rgb, uColor.rgb, uColor.a );
}