#version 300 es
#extension GL_APPLE_clip_distance : require

in          vec3        aPosition;
in          vec2        aTexCoord;

out         vec2        vTexCoord;

uniform     mat4        uModelMatrix;
uniform     mat4        uViewMatrix;
uniform     mat4        uProjMatrix;

uniform     vec4        uAmbientColor;
uniform     vec4        uDiffuseColor;

uniform     vec3        uSpriteAxis;

uniform     vec4        uWaterPlane;

mat4 billboard( vec3 right, vec3 up, vec3 look, vec3 pos )
{
    return mat4( mat4x3( right, up, look, pos ) );
}

mat4 billboard_point( vec3 pos, vec3 eyePos, vec3 eyeUp )
{
    vec3 look   = normalize( eyePos - pos );
    vec3 right  = cross( eyeUp, look );
    vec3 up     = cross( look, right );
    
    return billboard( right, up, look, pos );
}

mat4 billboard_axis( vec3 pos, vec3 eyePos, vec3 axis )
{
    vec3 look   = normalize( eyePos - pos );
    vec3 up     = axis;
    vec3 right  = normalize( cross( up, look ) );
         look   = cross( right, up );
    
    return billboard( right, up, look, pos );
}

void main()
{
    mat4 view = uViewMatrix;
    
    mat4 billboardMatrix;
    if ( length( uSpriteAxis ) == 0.0 )
        billboardMatrix = billboard_point( vec3(0,0,0), vec3( transpose(view)[2] ), vec3( view[1] ) );
    else
        billboardMatrix = billboard_axis( vec3(0,0,0), vec3( transpose(view)[2] ), normalize( uSpriteAxis ) );
    
    mat4 model = uModelMatrix * billboardMatrix;
    
    gl_Position = model * vec4( aPosition, 1 );
    
    vec4 plane = uWaterPlane;
    gl_ClipDistance[ 0 ] = dot( gl_Position, vec4( plane.xyz, plane.w + 0.02 ) );
    
    gl_Position = uProjMatrix * uViewMatrix * gl_Position;
    
    vTexCoord = aTexCoord;
}





