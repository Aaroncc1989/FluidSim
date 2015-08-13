#version 150 core

uniform mat4 viewMatrix;
uniform mat4 modelMatrix;

in vec3 position;
out vec2 coords;
//out mat3 normalMatrix;

void main(void) {
	coords = (position.xy + 1.0f) / 2.0f;
	//normalMatrix = transpose(inverse(mat3(viewMatrix)));
	gl_Position = vec4(position, 1.0);
}