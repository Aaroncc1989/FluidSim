#version 150 core

uniform sampler2D diffuseTex ;
uniform int useTexture;
uniform vec2 pixelSize;

in Vertex{
	vec2 texCoord;
	vec4 colour;
}IN;

out vec4 gl_FragColor;

void main (void){
	if (useTexture == 0)
	{
		gl_FragColor = IN.colour;
		return;
	}

	gl_FragColor = texture2D(diffuseTex, IN.texCoord);

	//test
	//vec2 pos = vec2((gl_FragCoord.x * pixelSize.x), (gl_FragCoord.y * pixelSize.y));
	//if (IN.texCoord.x == pos.x && IN.texCoord.y == pos.y)
	//{
	//	gl_FragColor = vec4(1,0,0,1);
	//}
	//gl_FragColor = vec4(gl_FragCoord.xy, 0, 1);
}