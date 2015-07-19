#version 150 core

uniform sampler2D diffuseTex;
uniform sampler2D thicknessTex;

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
 
vec3 getEyePos(vec2 texCoord,vec2 offset){
	float depth = texture(diffuseTex, texCoord + offset).r;
	if (depth == 0.0f)
	{
		depth = texture(diffuseTex, texCoord).r;
	}
	return uvToEye(texCoord, depth);
}

vec3 eyespaceNormal(vec2 pos) {
	vec2 screenSize = vec2(0);
	screenSize.x = 1.0f / pixelSize.x;
	screenSize.y = 1.0f / pixelSize.y;

	vec2 dx = vec2(pixelSize.x, 0.0f);
	vec2 dy = vec2(0.0f, pixelSize.y);

	float zc = texture(diffuseTex, pos);

	float zdxp = texture(diffuseTex, pos + dx);
	float zdxn = texture(diffuseTex, pos - dx);
	float zdx = (zdxp == 0.0f) ? (zdxn == 0.0f ? 0.0f : (zc - zdxn)) : (zdxp - zc);

	float zdyp = texture(diffuseTex, pos + dy);
	float zdyn = texture(diffuseTex, pos - dy);
	float zdy = (zdyp == 0.0f) ? (zdyn == 0.0f ? 0.0f : (zc - zdyn)) : (zdyp - zc);

	float cx = 2.0f / (screenSize.x * -projMatrix[0][0]);
	float cy = 2.0f / (screenSize.y * -projMatrix[1][1]);

	float sx = floor(pos.x * (screenSize.x - 1.0f));
	float sy = floor(pos.y * (screenSize.y - 1.0f));
	float wx = (screenSize.x - 2.0f * sx) / (screenSize.x * projMatrix[0][0]);
	float wy = (screenSize.y - 2.0f * sy) / (screenSize.y * projMatrix[1][1]);

	vec3 pdx = normalize(vec3(cx * zc + wx * zdx, wy * zdx, zdx));
	vec3 pdy = normalize(vec3(wx * zdy, cy * zc + wy * zdy, zdy));

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

void main (void){
	float depth = texture(diffuseTex, coords);
	if (depth == 0.0f){ discard;}
	float thickness = texture(thicknessTex, coords);
	//calculate normal
	vec3 normal = eyespaceNormal(coords);

	vec3 lightDir = vec3(1.0f,1.0f,1.0f);
	vec4 particleColor = exp(-vec4(0.6f, 0.2f, 0.05f, 3.0f) * thickness/10.0f);
	float lambert = max(0.0f, dot(normal,normalize(lightDir)));
	
	gl_FragColor = vec4(lambert * particleColor.xyz, 1.0f);

	//gl_FragColor = vec4(vec3(depth), 1.0f);
}