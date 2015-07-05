#version 150 core

uniform mat4 modelMatrix;
uniform mat4 viewMatrix;
uniform mat4 projMatrix;
uniform mat4 textureMatrix;
uniform int point;
uniform float pointRadius;

in vec3 position;
in vec4 colour;
in vec2 texCoord;

out Vertex{
	vec2 texCoord;
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
	OUT.texCoord = (textureMatrix * vec4(texCoord, 0.0, 1.0)).xy;
	OUT.colour = colour;
}