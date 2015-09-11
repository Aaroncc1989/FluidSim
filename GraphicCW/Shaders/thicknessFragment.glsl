#version 150 core
uniform vec2 pixelSize;
uniform mat4 projMatrix;

in float density;
out float thickness;

void main(void){
	vec3 normal = vec3(0);
	normal.xy = (gl_PointCoord - 0.5f) * 2.0f;
	float dist = dot(normal,normal);
	if (dist >  1.0f){ discard; }

	thickness = 1 - dist;
}
