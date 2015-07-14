#version 150 core
uniform vec2 pixelSize;
uniform mat4 projMatrix;

in Vertex {
	float eyespaceRadius;
	vec3 eyespacePos;
}IN;

out float particleDepth;

void main(void){
	vec3 normal = vec3(0);
	normal.xy = (gl_PointCoord - 0.5f) * 2.0f;
	float dist = length(normal);
	if (dist >  1.0f){ discard; }

	normal.z = sqrt(1.0f-dist);
	normal.y = -normal.y;
	normal = normalize(normal);

	normal = vec3(normal.x * IN.eyespaceRadius * pixelSize.x, normal.y * IN.eyespaceRadius * pixelSize.y, normal.z);
	//vec4 fragPos = vec4(IN.eyespacePos + normal * IN.eyespaceRadius * pixelSize.y, 1.0f);
	vec4 fragPos = vec4(IN.eyespacePos + normal, 1.0f);

	vec4 clipspacePos = projMatrix * fragPos;
	float far = gl_DepthRange.far;
	float near = gl_DepthRange.near;
	float devDepth = clipspacePos.z / clipspacePos.w;
	float fragDepth = (((far - near) * devDepth) + near + far) / 2.0;
	gl_FragDepth = fragDepth;
	particleDepth = clipspacePos.z;
}


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
