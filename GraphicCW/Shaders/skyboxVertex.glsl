#version 150 core

uniform mat4 modelMatrix;
uniform mat4 viewMatrix;
uniform mat4 projMatrix;

in  vec3 position;
out Vertex {
	vec3 normal;
} OUT;

void main(void)		{
	vec3 multiply = vec3(0,0,0);
	mat4 invproj  = inverse(projMatrix);
	multiply.x	   = invproj[0][0];
	multiply.y      = invproj[1][1];

	vec3 tempPos	= (position * multiply) - vec3(0,0,1);
	OUT.normal	= inverse(mat3(viewMatrix)) * normalize(tempPos);
	gl_Position		= vec4(position, 1.0);
}