#version 150 core

uniform sampler2D diffuseTex ;
uniform sampler2D depTex;
uniform int useTexture;

in Vertex{
	vec2 texCoord;
	vec4 colour;
}IN;

out vec4 gl_FragColor;

void main (void){
	if (useTexture == 0)
	{
		gl_FragColor = IN.colour;
	}
	else
	{
		gl_FragColor = texture2D(diffuseTex, IN.texCoord);
		//gl_FragColor = texture2D(depTex, IN.texCoord);
	}
}