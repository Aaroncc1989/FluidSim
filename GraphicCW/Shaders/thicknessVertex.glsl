#version 150 core

uniform mat4 modelMatrix;
uniform mat4 viewMatrix;
uniform mat4 projMatrix;

uniform vec2 pixelSize;
uniform float pointRadius;

in vec4 position;
out float density;

void main(void) {
	vec4 posEye = viewMatrix * modelMatrix * vec4(position.xyz, 1.0);
	float dist = length(vec3(posEye));
	gl_PointSize = pointRadius * 40000.0f / dist;

	gl_Position = projMatrix * posEye;
	density = position.w;
}