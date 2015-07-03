#version 150 core

uniform mat4 modelMatrix;
uniform mat4 viewMatrix;
uniform mat4 projMatrix;
uniform int point;
uniform float pointRadius;
in vec3 position;
in vec4 colour;

out Vertex {
vec4 colour ;
}OUT;

void main(void) {
	mat4 mvp = projMatrix * viewMatrix * modelMatrix;
	gl_Position = mvp * vec4(position, 1.0);
	if (point == 1)
	{
		//vec3 posEye = vec3(gl_Position);
		//float dist = length(posEye);
		gl_PointSize = pointRadius*500;
	}	
	OUT.colour = colour;
}