#version 150 core

uniform sampler2D diffuseTex ;
uniform int useColor;
uniform vec2 pixelSize;

in Vertex{
	vec2 texCoord;
	vec4 colour;
}IN;

out vec4 gl_FragColor;

void main (void){
	if (useColor == 1)
	{
		gl_FragColor = IN.colour;
		return;
	}
	float c = texture2D(diffuseTex, IN.texCoord);
	gl_FragColor = vec4(c,0,0,1);
}