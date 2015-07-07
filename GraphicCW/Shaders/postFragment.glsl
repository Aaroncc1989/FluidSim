#version 150 core
uniform int point;
uniform vec2 pixelSize;
uniform mat4 projMatrix;
uniform sampler2D depTex;

in Vertex {
	vec2 texCoord;
	vec4 colour;
}IN;

out vec4 gl_FragColor[2];

void main(void){
	if (point == 0)
	{
		gl_FragColor[0] = IN.colour;
		gl_FragColor[1] = IN.colour;
		return;
	}

	if (dot(gl_PointCoord - 0.5, gl_PointCoord - 0.5) > 0.25)
			discard;
	else   gl_FragColor[0] = IN.colour;
	gl_FragColor[1] = IN.colour;	

	//vec3 pos = vec3((gl_FragCoord.x * pixelSize.x), (gl_FragCoord.y * pixelSize.y), gl_FragCoord.z);
	//float depth = texture(depTex, pos.xy);
	//gl_FragDepth = gl_FragCoord.z;
	//if (depth == 0.0f)
	//{
		//gl_FragDepth = depth;
	//}
	//else
	//{
	//	const float dt = 0.00055f;
	//	const float dzt = 1000.0f;
		//vec3 dxyz = calCurFlow(IN.texCoord);
		//gl_FragDepth = depth + dxyz.z * dt * (1.0f + (abs(dxyz.x) + abs(dxyz.y)) * dzt);
//	}
}



//vec3 calCurFlow(vec2 texCoord)
//{
	//vec2 dx = vec2(pixelSize.x,0);
	//vec2 dy = vec2(0, pixelSize.y);

	//float zc = texture(depTex, texCoord);

	//float zdxp = texture(depTex, texCoord + dx);
	//float zdxn = texture(depTex, texCoord - dx);
	//float zdx = 0.5f * (zdxp - zdxn);
	//zdx = (zdxp == 0.0f || zdxn == 0.0f) ? 0.0f : zdx;

	//float zdyp = texture(depTex, texCoord + dx);
	//float zdyn = texture(depTex, texCoord - dy);
	//float zdy = 0.5f * (zdyp - zdyn);
	//zdy = (zdyp == 0.0f || zdyn == 0.0f) ? 0.0f : zdy;

	//float zdx2 = zdxp + zdxn - 2.0f * zc;
	//float zdy2 = zdyp + zdyn - 2.0f * zc;

	//float zdxpyp = texture(depTex, texCoord + dx + dy);
	//float zdxnyn = texture(depTex, texCoord - dx - dy);
	//float zdxpyn = texture(depTex, texCoord + dx - dy);
	//float zdxnyp = texture(depTex, texCoord - dx + dy);
	//float zdxy = (zdxpyp + zdxnyn - zdxpyn - zdxnyp) / 4.0f;

	//float cx = -pixelSize * 2.0f / projMatrix[0][0];
	//float cy = -pixelSize * 2.0f / projMatrix[1][1];

	//float d = cy * cy * zdx * zdx + cx * cx * zdy * zdy + cx * cx * cy * cy * zc * zc;

	//float ddx = cy * cy * 2.0f * zdx * zdx2 + cx * cx * 2.0f * zdy * zdxy + cx * cx * cy * cy * 2.0f * zc * zdx;
	//float ddy = cy * cy * 2.0f * zdx * zdxy + cx * cx * 2.0f * zdy * zdy2 + cx * cx * cy * cy * 2.0f * zc * zdy;

	//float ex = 0.5f * zdx * ddx - zdx2 * d;
	//float ey = 0.5f * zdy * ddy - zdy2 * d;

	//float h = 0.5f * ((cy * ex + cx * ey) / pow(d, 1.5f));

	//return(vec3(zdx, zdy, h));
//}


//#version 330
//uniform mat4 u_Persp;
//uniform mat4 u_InvTrans;
//uniform mat4 u_InvProj;
//
//uniform sampler2D u_Depthtex;
//uniform sampler2D u_Positiontex;
//
//uniform float u_Far;
//uniform float u_Near;
//
//in vec2 fs_Texcoord;
//
//out vec4 out_Normal;
//
////Depth used in the Z buffer is not linearly related to distance from camera
////This restores linear depth
//
//float linearizeDepth(float exp_depth, float near, float far) {
//	return	(2 * near) / (far + near - exp_depth * (far - near));
//}
//
//vec3 uvToEye(vec2 texCoord, float depth){
//	float x = texCoord.x * 2.0 - 1.0;
//	float y = texCoord.y * 2.0 - 1.0;
//	vec4 clipPos = vec4(x, y, depth, 1.0f);
//	vec4 viewPos = u_InvProj * clipPos;
//	return viewPos.xyz / viewPos.w;
//}
//
//vec3 getEyePos(in vec2 texCoord){
//	float exp_depth = texture(u_Depthtex, fs_Texcoord).r;
//	float lin_depth = linearizeDepth(exp_depth, u_Near, u_Far);
//	return uvToEye(texCoord, lin_depth);
//}
//
//void main()
//{
//	//Get Depth Information about the Pixel
//	float exp_depth = texture(u_Depthtex, fs_Texcoord).r;
//
//	//float lin_depth = linearizeDepth(exp_depth,u_Near,u_Far);
//	vec3 position = uvToEye(fs_Texcoord, exp_depth);
//
//	//vec3 ddx = getEyePos(fs_Texcoord + vec2(texelSize,0)) - position;
//	//vec3 ddx2 = position - texture(u_Positiontex,fs_Texcoord + vec2(-texelSize,0)).xyz;
//
//	//vec3 ddy = getEyePos(fs_Texcoord + vec2(0,texelSize)) - position;
//	//vec3 ddy2 = position - texture(u_Positiontex, fs_Texcoord + vec2(0, -texelSize)).xyz;
//
//	//out_Normal = vec4(normalize(cross(ddx, ddy)), 1.0f);
//	//out_Normal = vec4(position, 1.0f);
//
//	//Compute Gradients of Depth and Cross Product Them to Get Normal
//	out_Normal = vec4(normalize(cross(dFdx(position.xyz), dFdy(position.xyz))), 1.0f);
//}
