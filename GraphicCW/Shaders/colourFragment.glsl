#version 150 core
uniform int point;

in Vertex {
vec4 colour ;
}IN;

out vec4 gl_FragColor;

void main (void){
gl_FragColor = IN.colour;
if (point == 1)
{
	//vec2 center = gl_TexCoord[0];
	//float cendist = 1.0 - length(center)*2.0;
	//gl_FragColor = vec4(1, 0, 0, clamp(cendist, 0.0, 1.0));
}
}