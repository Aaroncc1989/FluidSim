#version 150 core

uniform sampler2D diffuseTex;

uniform vec2 pixelSize;
uniform mat4 projMatrix;
uniform mat4 modelViewMatrix;

in vec2 coords;
out vec4 gl_FragColor;

vec3 eyespaceNormal(vec2 pos) {
	vec2 dx = vec2(pixelSize.x, 0.0f);
	vec2 dy = vec2(0.0f, pixelSize.y);

	float zc = texture(diffuseTex, pos);

	//float zdxp = texture(diffuseTex, pos + dx);
	//float zdxn = texture(diffuseTex, pos - dx);
	//float zdx = (zdxp == 0.0f) ? (zdxn == 0.0f ? 0.0f : (zc - zdxn)) : (zdxp - zc);

	//float zdyp = texture(diffuseTex, pos + dy);
	//float zdyn = texture(diffuseTex, pos - dy);
	//float zdy = (zdyp == 0.0f) ? (zdyn == 0.0f ? 0.0f : (zc - zdyn)) : (zdyp - zc);

	float zdxp = texture(diffuseTex, pos + dx);
	float zdxn = texture(diffuseTex, pos - dx);
	float zdx = 0.5f * (zdxp - zdxn);
	//zdx = (zdxp == 0.0f || zdxn == 0.0f) ? 0.0f : zdx;

	float zdyp = texture(diffuseTex, pos + dy);
	float zdyn = texture(diffuseTex, pos - dy);
	float zdy = 0.5f * (zdyp - zdyn);
	//zdy = (zdyp == 0.0f || zdyn == 0.0f) ? 0.0f : zdy;


	vec2 screenSize = vec2(1.0f / pixelSize.x, 1.0f / pixelSize.y);
	float cx = -2.0f / (screenSize.x * projMatrix[0][0]);
	float cy = -2.0f / (screenSize.y * projMatrix[1][1]);

	float sx = floor(pos.x * (screenSize.x - 1.0f));
	float sy = floor(pos.y * (screenSize.y - 1.0f));
	float wx = (screenSize.x - 2.0f * sx) / (screenSize.x * projMatrix[0][0]);
	float wy = (screenSize.y - 2.0f * sy) / (screenSize.y * projMatrix[1][1]);

	vec3 pdx = normalize(vec3(cx * zc + wx * zdx, wy * zdx, zdx));
	vec3 pdy = normalize(vec3(wx * zdy, cy * zc + wy * zdy, zdy));

	if (zc - zdxp == 0 && zc - zdxn == 0){ return vec3(0); }

	return normalize(cross(pdx, pdy));
}

vec3 eyespacePos(vec2 pos) {
	float depth = texture(diffuseTex, pos);
	pos = (pos - vec2(0.5f)) * 2.0f;
	return(depth * vec3(-pos.x * projMatrix[0][0], -pos.y * projMatrix[1][1], 1.0f));
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
	float particleDepth = texture(diffuseTex, coords);
	vec3 normal = eyespaceNormal(coords);
	//normal = inverse(mat3(modelViewMatrix)) * normal;
	//normal.xz = -normal.xz;

	vec3 lightDir = vec3(1.0f, 1.0f, -1.0f);

	if (particleDepth == 0.0f) {
		gl_FragColor = vec4(0.0f);
	}
	else
	{
		vec3 pos = eyespacePos(coords);
		pos = (inverse(modelViewMatrix) * vec4(pos, 1.0f)).xyz;

		float lambert = max(0.0f, dot(normal,normalize(lightDir)));

		vec3 fromEye = normalize(pos);
		fromEye.xz = -fromEye.xz;
		vec3 reflectedEye = normalize(reflect(fromEye, normal));
		float specular = clamp(fresnel(1.0f, 1.5f, normal, fromEye), 0.0f, 0.4f);

		vec4  particleColor = exp(-vec4(0.6f, 0.2f, 0.05f, 3.0f));
		//particleColor.w = clamp(1.0f - particleColor.w, 0.0f, 1.0f);
		//particleColor.rgb = particleColor.rgb * (1.0f - specular);
		particleColor.w = 1.0f;
		particleColor.rgb = (lambert*100.0f ) * particleColor.rgb * (1 - specular) + particleColor.rgb * 0.2f;
		//gl_FragColor = particleColor;
		gl_FragColor = vec4(normal,1.0f);
	}
}