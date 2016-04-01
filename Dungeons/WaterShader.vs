#version 300 es

in          vec3        aPosition;
//in          vec3        aNormal;
//in          vec2        aTexCoord;

out         vec4        vClipSpace;
out         vec3        vEyeNormal;
out         vec2        vTexCoord;
out         vec3        vLightDirection;

uniform     mat4        uModelMatrix;
uniform     mat4        uViewMatrix;
uniform     mat4        uProjMatrix;
uniform     vec3        uEyePosition;
uniform     vec3        uSunPosition;

const       float       TILING              = 4.0;

void main()
{
    mat4 vp = uProjMatrix * uViewMatrix;
    vec4 worldPos = uModelMatrix * vec4( aPosition, 1 );

    gl_Position = vp * worldPos;
    
    vClipSpace = gl_Position;
    vEyeNormal = worldPos.xyz - uEyePosition;
    vLightDirection = worldPos.xyz - uSunPosition;

    vTexCoord = (aPosition.xz / 2.0 + 0.5) / TILING;
}