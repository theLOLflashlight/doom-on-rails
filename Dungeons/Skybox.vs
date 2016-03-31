#version 300 es

in          vec3    aPosition;

out         vec3    vCubeCoord;

uniform     mat4    uViewMatrix;
uniform     mat4    uProjMatrix;

void main()
{
    mat4 view = uViewMatrix;
    view[ 3 ] = vec4( 0, 0, 0, view[ 3 ][ 3 ] );

    gl_Position = uProjMatrix * view * vec4( aPosition, 1 );
    vCubeCoord = aPosition;
}