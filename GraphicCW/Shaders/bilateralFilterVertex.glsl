#version 150 core

in vec3 position;
out vec2 coords;

void main(void) {
	coords = (position.xy + 1.0f) / 2.0f;
	gl_Position = vec4(position, 1.0);
}