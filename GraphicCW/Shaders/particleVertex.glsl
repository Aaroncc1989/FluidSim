#version 150 core

uniform mat4 modelMatrix;
uniform mat4 viewMatrix;
uniform mat4 projMatrix;

uniform vec2 pixelSize;
uniform float pointRadius;

in vec4 position;

out Vertex{
	float eyespaceRadius;
	vec3  eyespacePos;
	float  density;
}OUT;

void main(void) {
	vec4 posEye = viewMatrix * modelMatrix * vec4(position.xyz, 1.0);

	float dist = length(vec3(posEye));
	gl_PointSize = pointRadius * 24000.0f / dist;
	float density = position.w;
	if (density > 5.0f)
	{
		density = 5.0f;
	}
	gl_PointSize = gl_PointSize * density / 5.0f;

	OUT.eyespaceRadius = gl_PointSize;
	gl_Position = projMatrix * posEye;
	OUT.eyespacePos = posEye.xyz;
	OUT.density = position.w;
}