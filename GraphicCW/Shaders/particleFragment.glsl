#version 150 core
uniform vec2 pixelSize;
uniform mat4 projMatrix;

in Vertex{
	float eyespaceRadius;
	vec3  eyespacePos;
	float  density;
}IN;

out float depth;

float projectZ(float z, float near, float far) {
	return far*(z + near) / (z*(far - near));
}

void main(void){
	vec3 normal = vec3(0);
	normal.xy = (gl_PointCoord - 0.5f) * 2.0f;
	float dist = dot(normal, normal);
	if (dist >  1.0f){ discard; }
	normal.y = -normal.y;
	normal.z = sqrt(1.0f - dist);

	float z = IN.eyespacePos.z + normal.z * IN.eyespaceRadius;
	gl_FragDepth = projectZ(z, 1.0f, 10000.0f);
	//depth = z+5000.0f;
	depth = z;
}
