#version 150 core

uniform mat4 modelMatrix;
uniform mat4 viewMatrix;
uniform mat4 projMatrix;
uniform int point;
in vec3 position;
in vec4 colour;

out Vertex {
vec4 colour ;
}OUT;

void main(void) {
	//gl_PointSize = 5.0f;
	if (point == 1)
	{
		//gl_TexCoord[0] = gl_MultiTexCoord0;
	}	
	gl_Position = (projMatrix * viewMatrix * modelMatrix) * vec4(position, 1.0);
	OUT.colour = colour;
}