#version 300 es
precision highp float;

in          vec3        vEyePosition;
in          vec3        vEyeNormal;
in          vec2        vTexCoord;
//in          vec4        vSpecColor;

uniform     sampler2D   uTexture;
uniform     vec4        uColor;
uniform     vec3        uSunPosition;
//uniform     vec3        uLightPosition;

uniform     vec4        uAmbientColor;
uniform     vec4        uDiffuseColor;
uniform     vec4        uSpecularColor;
uniform     float       uShininess;

out         vec4        out_Color;

void main()
{
    vec4 Ka = uAmbientColor;

    vec3 N = normalize( vEyeNormal );
    vec4 Kd = uDiffuseColor * max( 0.0, dot( N, normalize( uSunPosition ) ) );

    vec3 E = normalize( -vEyePosition );
    vec3 L = normalize( uSunPosition - vEyePosition );
    vec3 H = normalize( L + E );

    float Ns = pow( max( dot( N, H ), 0.0 ), uShininess );
    vec4 Ks = Ns * uSpecularColor;
    if ( dot( L, N ) < 0.0 )
    {
        Ks = vec4( 0, 0, 0, 1 );
    }

    out_Color = (Ka + Kd + Ks) * texture( uTexture, vTexCoord );
    out_Color.rgb = mix( out_Color.rgb, uColor.rgb, uColor.a );
}