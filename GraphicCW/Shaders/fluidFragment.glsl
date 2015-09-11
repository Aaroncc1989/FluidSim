#version 150 core

uniform sampler2D diffuseTex;
uniform sampler2D thicknessTex;

uniform vec2 pixelSize;
uniform mat4 projMatrix;
uniform mat4 viewMatrix;

uniform vec3 cameraPos;
uniform float lightRadius;
uniform vec3 lightPos;
uniform vec4 lightColour;

in vec2 coords;
in mat4 inverseProjView;
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
	float zdx = (zdxp == 0.0f) ? (zdxn == 0.0f ? 0.0f : (zc - zdxn)) : (zdxp - zc);

	float zdyp = texture(diffuseTex, pos + dy);
	float zdyn = texture(diffuseTex, pos - dy);
	float zdy = (zdyp == 0.0f) ? (zdyn == 0.0f ? 0.0f : (zc - zdyn)) : (zdyp - zc);

	float cx = -2.0f / (screenSize.x * projMatrix[0][0]);
	float cy = -2.0f / (screenSize.y * projMatrix[1][1]);

	float sx = floor(pos.x * (screenSize.x - 1.0f));
	float sy = floor(pos.y * (screenSize.y - 1.0f));
	float wx = (screenSize.x - 2.0f * sx) / (screenSize.x * projMatrix[0][0]);
	float wy = (screenSize.y - 2.0f * sy) / (screenSize.y * projMatrix[1][1]);

	vec3 pdx = (vec3(cx * zc + wx * zdx, wy * zdx, zdx));
	vec3 pdy = (vec3(wx * zdy, cy * zc + wy * zdy, zdy));

	return normalize(cross(pdx, pdy));
}

float projectZ(float z, float near, float far) {
	return far*(z + near) / (z*(far - near));
}

void main(void){
	float z = texture(diffuseTex, coords);
	if (z == 0.0f){ discard; }
	float depth = projectZ(z, 1.0f, 10000.0f);
	gl_FragDepth = depth;

	//calculate normal
	vec3 normal = eyespaceNormal(coords);
	normal = normalize(transpose(mat3(viewMatrix)) * normal);

	vec3 pos = vec3((gl_FragCoord.x * pixelSize.x),
		(gl_FragCoord.y * pixelSize.y), 0.0);
	pos.z = depth;

	vec4 clip = inverseProjView * vec4(pos * 2.0 - 1.0, 1.0);
	pos = clip.xyz / clip.w;
	float dist = length(lightPos - pos);
	float atten = 1.0 - clamp(dist / lightRadius, 0.0, 1.0);
	if (atten == 0.0) {
		discard;
	}

	vec3 incident = normalize(lightPos - pos);
	vec3 viewDir = normalize(cameraPos - pos);
	vec3 halfDir = normalize(incident + viewDir);

	float lambert = clamp(dot(incident, normal), 0.0, 1.0);
	float rFactor = clamp(dot(halfDir, normal), 0.0, 1.0);
	float sFactor = pow(rFactor, 33.0);

	float thickness = texture(thicknessTex, coords);
	thickness /= 5.0f;
	vec4 diffuse = vec4(exp(-0.6f*thickness), exp(-0.2f*thickness), exp(-0.05f*thickness), 1 - exp(-3.0f*thickness));

	gl_FragColor.xyz = diffuse.xyz * 0.2;
	gl_FragColor.xyz += diffuse.xyz * lightColour.xyz * lambert * atten;
	gl_FragColor.xyz += lightColour.xyz * sFactor * atten * 0.33f;
	gl_FragColor.w = diffuse.w;
	//gl_FragColor = vec4(normal, 1.0f);
	//gl_FragColor = vec4(vec3(thickness), 1.0f);
}