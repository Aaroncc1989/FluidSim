#version 150 core
uniform vec2 pixelSize;
uniform mat4 projMatrix;

in Vertex {
	float eyespaceRadius;
	vec3  eyespacePos;
	vec4  color;
}IN;

out float thickness;

void main(void){
	vec3 normal = vec3(0);
	normal.xy = (gl_PointCoord - 0.5f) * 2.0f;
	float dist = dot(normal,normal);
	if (dist >  1.0f){ discard; }

	thickness = 1 - dist;

	//normal.y = -normal.y;
	//normal.z = sqrt(1.0f-dist);

	//vec4 fragPos = vec4(IN.eyespacePos + normal * IN.eyespaceRadius, 1.0f);
	//vec4 clipspacePos = projMatrix * fragPos;
	//
	//float far = gl_DepthRange.far;
	//float near = gl_DepthRange.near;
	//float deviceDepth = clipspacePos.z / clipspacePos.w;
	//float fragDepth = (((far - near) * deviceDepth) + near + far) / 2.0;
	//gl_FragDepth = fragDepth;
}