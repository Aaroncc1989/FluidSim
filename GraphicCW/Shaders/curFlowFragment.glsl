#version 150 core

uniform sampler2D diffuseTex;

uniform vec2 pixelSize;
uniform mat4 projMatrix;

in vec2 coords;
out float outDepth;

vec3 curFlowSmoothing(vec2 pos)
{
	vec2 dx = vec2(pixelSize.x, 0.0f);
	vec2 dy = vec2(0.0f, pixelSize.y);

	float zc = texture(diffuseTex, pos);

	float zdxp = texture(diffuseTex, pos + dx);
	float zdxn = texture(diffuseTex, pos - dx);
	if (zdxp == 0.0f ) zdxp = zc;
	if (zdxn == 0.0f) zdxn = zc;
	float zdx = 0.5f * (zdxp - zdxn);
	//zdx = (zdxp == 0.0f || zdxn == 0.0f) ? 0.0f : zdx;

	float zdyp = texture(diffuseTex, pos + dy);
	float zdyn = texture(diffuseTex, pos - dy);
	if (zdyp == 0.0f) zdyp = zc;
	if (zdyn == 0.0f) zdyn = zc;
	float zdy = 0.5f * (zdyp - zdyn);
	//zdy = (zdyp == 0.0f || zdyn == 0.0f) ? 0.0f : zdy;

	float zdx2 = zdxp + zdxn - 2.0f * zc;
	float zdy2 = zdyp + zdyn - 2.0f * zc;

	float zdxpyp = texture(diffuseTex, pos + dx + dy);
	float zdxnyn = texture(diffuseTex, pos - dx - dy);
	float zdxpyn = texture(diffuseTex, pos + dx - dy);
	float zdxnyp = texture(diffuseTex, pos - dx + dy);
	if (zdxpyp == 0) zdxpyp = zc;
	if (zdxnyn == 0) zdxnyn = zc;
	if (zdxpyn == 0) zdxpyn = zc;
	if (zdxnyp == 0) zdxnyp = zc;
	float zdxy = (zdxpyp + zdxnyn - zdxpyn - zdxnyp) / 4.0f;

	float cx = 2.0f * pixelSize.x / (-projMatrix[0][0]);
	float cy = 2.0f * pixelSize.y / (-projMatrix[1][1]);

	float d = cy * cy * zdx * zdx + cx * cx * zdy * zdy + cx * cx * cy * cy * zc * zc;

	float ddx = cy * cy * 2.0f * zdx * zdx2 + cx * cx * 2.0f * zdy * zdxy + cx * cx * cy * cy * 2.0f * zc * zdx;
	float ddy = cy * cy * 2.0f * zdx * zdxy + cx * cx * 2.0f * zdy * zdy2 + cx * cx * cy * cy * 2.0f * zc * zdy;

	float ex = 0.5f * zdx * ddx - zdx2 * d;
	float ey = 0.5f * zdy * ddy - zdy2 * d;

	float h = 0.5f * ((cy * ex + cx * ey) / pow(d, 1.5f));
	return(vec3(zdx, zdy, h));
}


void main (void){
	float particleDepth = texture(diffuseTex, coords);

	if (particleDepth == 0.0f) {
		outDepth = 0.0f;
	}
	else {
		const float dt = 0.06f;
		const float dzt = 10.0f;
		vec3 dxyz = curFlowSmoothing(coords);

		outDepth = particleDepth + dxyz.z * dt * (1.0f + (abs(dxyz.x) + abs(dxyz.y)) * dzt);
	}
}