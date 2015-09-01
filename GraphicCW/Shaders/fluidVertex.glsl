#version 150 core

uniform mat4 viewMatrix;
uniform mat4 modelMatrix;
uniform mat4 projMatrix;

in vec3 position;
out vec2 coords;
out mat4 inverseProjView;

void main(void) {
	coords = (position.xy + 1.0f) / 2.0f;
	gl_Position = vec4(position, 1.0);
	inverseProjView = inverse(projMatrix * viewMatrix);
}