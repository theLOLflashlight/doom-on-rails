// Andrew
#version 300 es
#extension GL_APPLE_clip_distance : require

in          vec3        aPosition;
in          vec3        aNormal;
in          vec2        aTexCoord;

out         vec3        vEyePosition;
out         vec3        vEyeNormal;
out         vec2        vTexCoord;

uniform     mat4        uModelMatrix;
uniform     mat4        uViewMatrix;
uniform     mat4        uProjMatrix;

uniform     vec3        uSunPosition;

uniform     vec4        uAmbientColor;
uniform     vec4        uDiffuseColor;
uniform     vec4        uSpecularColor;
uniform     float       uShininess;

uniform     vec4        uWaterPlane;

vec4 extract_eye_pos( mat4 model, mat4 view )
{
    mat4 model_view = view * model;
    vec4 d          = vec4( model_view[3].xyz, 1 );
    return -d * model_view;
    //return vec4( (model * view)[3] );
}

void main()
{
    gl_Position = uModelMatrix * vec4( aPosition, 1 );

    vec4 plane = uWaterPlane;
    gl_ClipDistance[ 0 ] = dot( gl_Position, vec4( plane.xyz, plane.w + 0.02 ) );

    gl_Position = uProjMatrix * uViewMatrix * gl_Position;

    vTexCoord = aTexCoord;
    vEyePosition = (uViewMatrix * uModelMatrix)[3].xyz;

    mat3 normalMatrix = transpose( inverse( mat3( uModelMatrix ) ) );
    vEyeNormal = normalize( normalMatrix * aNormal );

    float nDotVP = max( 0.0, dot( vEyeNormal, normalize( uSunPosition ) ) );

    //vSpecColor = uSpecularColor * nDotVP;
}