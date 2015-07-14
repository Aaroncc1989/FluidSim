#version 150 core

uniform mat4 modelMatrix;
uniform mat4 viewMatrix;
uniform mat4 projMatrix;

uniform vec2 pixelSize;
uniform float pointRadius;

in vec3 position;

out Vertex{
	float eyespaceRadius;
	vec3 eyespacePos;
}OUT;

void main(void) {
	vec4 posEye = viewMatrix * modelMatrix * vec4(position, 1.0);
	float dist = length(vec3(posEye));
	gl_PointSize = pointRadius * 120000.0f / dist;

	OUT.eyespaceRadius = gl_PointSize;

	gl_Position = projMatrix * posEye;
	OUT.eyespacePos = posEye.xyz;
}