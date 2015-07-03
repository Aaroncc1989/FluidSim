#version 150 core

uniform mat4 modelMatrix;
uniform mat4 viewMatrix;
uniform mat4 projMatrix;
uniform int point;
uniform float pointRadius;
in vec3 position;
in vec4 colour;

out Vertex{
	vec4 colour;
}OUT;

void main(void) {
	vec4 posEye = viewMatrix * modelMatrix * vec4(position, 1.0);
	gl_Position = projMatrix * posEye;
	if (point == 1)
	{
		float dist = length(vec3(posEye));
		gl_PointSize = pointRadius * 100000.0f / dist;
	}
	OUT.colour = colour;
}