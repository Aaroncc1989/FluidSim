#version 150 core

uniform sampler2D diffuseTex;
uniform sampler2D depthTex;

uniform vec2 pixelSize;
uniform mat4 projMatrix;
uniform mat4 modelViewMatrix;

in vec2 coords;
out vec4 gl_FragColor;

float linearizeDepth(float exp_depth, float near, float far) {
	return	(2.0f * near) / (far + near - exp_depth * (far - near));
}

vec3 uvToEye(vec2 texCoord, float depth){
	float x = texCoord.x * 2.0 - 1.0;
	float y = texCoord.y * 2.0 - 1.0;
	vec4 clipPos = vec4(x, y, depth, 1.0f);
	vec4 viewPos = inverse(projMatrix) * clipPos;
	return viewPos.xyz / viewPos.w;
}

vec3 getEyePos(vec2 texCoord){
	float depth = texture(depthTex, texCoord).r;
	float linDepth = linearizeDepth(depth, 1.0f, 1000.0f);
	return uvToEye(texCoord, linDepth);
}


float fresnel(float rr1, float rr2, vec3 n, vec3 d) {
	float r = rr1 / rr2;
	float theta1 = dot(n, -d);
	float theta2 = sqrt(1.0f - r * r * (1.0f - theta1 * theta1));

	float rs = (rr1 * theta1 - rr2 * theta2) / (rr1 * theta1 + rr2 * theta2);
	rs = rs * rs;
	float rp = (rr1 * theta2 - rr2 * theta1) / (rr1 * theta2 + rr2 * theta1);
	rp = rp * rp;

	return((rs + rp) / 2.0f);
}

void main (void){
	float depth = texture(depthTex, coords).r;
	vec4 color = texture(diffuseTex, coords);

	if (depth == 0){ discard;}

	float linDepth = linearizeDepth(depth, 1.0f, 1000.0f);
	vec3  posEye = uvToEye(coords, linDepth);

	vec3 ddx = getEyePos(coords + vec2(pixelSize.x, 0)) - posEye;
	vec3 ddx2 = posEye - getEyePos(coords - vec2(pixelSize.x, 0));
	if (abs(ddx.z) > abs(ddx2.z)) {
		ddx = ddx2;
	}

	vec3 ddy = getEyePos(coords + vec2(0, pixelSize.y)) - posEye;
	vec3 ddy2 = posEye - getEyePos(coords - vec2(0, pixelSize.y));
	if (abs(ddy2.z) < abs(ddy.z)) {
		ddy = ddy2;
	}

	vec3 normal = normalize(cross(ddx, ddy));

	vec3 lightDir = vec3(1.0f,1.0f,1.0f);
	vec4 particleColor = exp(-vec4(0.6f, 0.2f, 0.05f, 3.0f));

	float lambert = max(0.0f, dot(normal,normalize(lightDir)));
	
	//gl_FragColor = vec4( color.xyz, 1.0f);
	gl_FragColor = vec4(vec3(depth), 1.0f);
	//gl_FragColor = vec4(normal, 1.0f);
}