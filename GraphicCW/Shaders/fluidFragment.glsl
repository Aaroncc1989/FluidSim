#version 150 core

uniform sampler2D diffuseTex;
uniform sampler2D thicknessTex;

uniform vec2 pixelSize;
uniform mat4 projMatrix;
uniform mat4 viewMatrix;

in vec2 coords;
//in mat3 normalMatrix;
out vec4 gl_FragColor;


vec3 eyespaceNormal(vec2 pos) {
	vec2 screenSize = vec2(0);
	screenSize.x = 1.0f / pixelSize.x;
	screenSize.y = 1.0f / pixelSize.y;

	vec2 dx = vec2(pixelSize.x, 0.0f);
	vec2 dy = vec2(0.0f, pixelSize.y);

	float zc = texture(diffuseTex, pos);

	float zdxp = texture(diffuseTex, pos + dx);
	float zdxn = texture(diffuseTex, pos - dx);
	//if (zdxp == 0) zdxp = zc;
	//if (zdxn == 0) zdxn = zc;
	float zdx = (zdxp == 0.0f) ? (zdxn == 0.0f ? 0.0f : (zc - zdxn)) : (zdxp - zc);

	float zdyp = texture(diffuseTex, pos + dy);
	float zdyn = texture(diffuseTex, pos - dy);
	//if (zdyp == 0) zdyp = zc;
	//if (zdyn == 0) zdyn = zc;
	float zdy = (zdyp == 0.0f) ? (zdyn == 0.0f ? 0.0f : (zc - zdyn)) : (zdyp - zc);

	float cx = 2.0f / (screenSize.x * -projMatrix[0][0]);
	float cy = 2.0f / (screenSize.y * -projMatrix[1][1]);

	float sx = floor(pos.x * (screenSize.x - 1.0f));
	float sy = floor(pos.y * (screenSize.y - 1.0f));
	float wx = (screenSize.x - 2.0f * sx) / (screenSize.x * projMatrix[0][0]);
	float wy = (screenSize.y - 2.0f * sy) / (screenSize.y * projMatrix[1][1]);

	vec3 pdx = (vec3(cx * zc + wx * zdx, wy * zdx, zdx));
	vec3 pdy = (vec3(wx * zdy, cy * zc + wy * zdy, zdy));

	return normalize(cross(pdx, pdy));
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

void main(void){
	float depth = texture(diffuseTex, coords);
	if (depth == 0.0f){ discard; }

	float thickness = texture(thicknessTex, coords);
	//calculate normal
	vec3 normal = eyespaceNormal(coords);
	normal = normalize(transpose(mat3(viewMatrix)) * normal);

	vec3 lightDir = vec3(0.577f, -0.577f, 0.577f);
	thickness /= 5.0f;
	vec4 particleColor = vec4(exp(-0.6f*thickness), exp(-0.2f*thickness), exp(-0.05f*thickness), 1 - exp(-3.0f*thickness));
	float lambert = abs(dot(normal, lightDir)) * 0.5f+0.5f;

	gl_FragColor = vec4(lambert * particleColor.xyz*0.8f + particleColor.xyz*0.2, 0.9f);
	//gl_FragColor = vec4(normal, 1.0f);
	//gl_FragColor = vec4(vec3(depth), 1.0f);
}