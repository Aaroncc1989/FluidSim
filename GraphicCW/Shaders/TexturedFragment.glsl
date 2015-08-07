#version 150 core

uniform sampler2D diffuseTex ;
uniform int useColor;

in Vertex{
	vec2 texCoord;
	vec4 colour;
	vec3 normal;
}IN;

out vec4 gl_FragColor;

void main (void){
	if (useColor == 1)
	{
		gl_FragColor = IN.colour;
		return;
	}
	gl_FragColor = texture2D(diffuseTex, IN.texCoord);
	gl_FragColor = vec4(IN.normal,1.0f);
}