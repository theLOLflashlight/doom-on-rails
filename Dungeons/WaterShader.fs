#version 300 es
precision highp float;

in          vec4        vClipSpace;
in          vec3        vEyeNormal;
in          vec2        vTexCoord;
in          vec3        vLightDirection;


uniform     vec4        uColor;
uniform     sampler2D   uTextureRefle;
uniform     sampler2D   uTextureRefra;
uniform     sampler2D   uMapDuDv;
uniform     sampler2D   uMapNormal;
uniform     sampler2D   uMapDepth;
uniform     vec3        uSunColor;

uniform     float       uDuDvFactor;

out         vec4        out_Color;

const       float       WAVE_STRENGTH       = 0.02;
const       float       SHINE_DAMPER        = 40.0;
const       float       REFLECTIVITY        = 0.5;

const       float       NEAR                = 0.1;
const       float       FAR                 = 1000.0;


void main()
{
    vec2 ndc = (vClipSpace.xy / vClipSpace.w) / 2.0 + 0.5;

    vec2 refleTexCoord = vec2( ndc.x, -ndc.y );
    vec2 refraTexCoord = ndc.xy;

    float floorDepth = 1.0;//texture( uMapDepth, refraTexCoord ).r;
    float floorDist = 2.0 * NEAR * FAR / (FAR + NEAR - (2.0 * floorDepth - 1.0) * (FAR - NEAR));

    float waterDist = 2.0 * NEAR * FAR / (FAR + NEAR - (2.0 * gl_FragCoord.z - 1.0) * (FAR - NEAR));
    float waterDepth = floorDist - waterDist;


    vec2 distor = texture( uMapDuDv, vec2( vTexCoord.x + uDuDvFactor, vTexCoord.y ) ).rg * 0.1;
    distor = vTexCoord + vec2( distor.x, distor.y + uDuDvFactor );
    distor = (texture( uMapDuDv, distor ).rg * 2.0 - 1.0) * WAVE_STRENGTH;

    float depthClamp = clamp( waterDepth / 5.0, 0.0, 1.0 );

    refleTexCoord += distor * clamp( waterDepth, 0.0, 1.0 );
    refleTexCoord.x = clamp( refleTexCoord.x, 0.001, 0.999 );
    refleTexCoord.y = clamp( refleTexCoord.y, -0.999, -0.001 );

    refraTexCoord += distor * depthClamp;
    refraTexCoord = clamp( refraTexCoord, 0.001, 0.999 );

    vec4 refleColor = texture( uTextureRefle, refleTexCoord );
    vec4 refraColor = texture( uTextureRefra, refraTexCoord );

    vec4 normalColor = texture( uMapNormal, distor );
    vec3 normal = normalize( vec3( normalColor.r * 2.0 - 1.0,
                                   normalColor.b * (3.0 + 2.0 * depthClamp),
                                   normalColor.g * 2.0 - 1.0 ) );

    vec3 viewVec = normalize( -vEyeNormal );
    float fresnl = dot( viewVec, normal );
    //fresnl = pow( fresnl, 1.1 );

    vec3 refleLight = reflect( normalize( vLightDirection ), normal );
    float specular = max( dot( refleLight, viewVec ), 0.0 );
    specular = pow( specular, SHINE_DAMPER );
    vec3 specHigh = uSunColor * specular * REFLECTIVITY * depthClamp;

    out_Color = mix( refleColor, refraColor, fresnl );
    out_Color = mix( out_Color, uColor, 0.2 ) + vec4( specHigh, 0.0 );
    
    //out_Color = vec4( depthClamp );
}





