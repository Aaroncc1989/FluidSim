#version 150 core

uniform sampler2D diffuseTex ;

in Vertex{
	vec2 coords;
}IN;

out vec4 gl_FragColor;

void main (void){
	float depth = texture2D(diffuseTex, IN.coords);
	if (depth == 0.0f){discard; }
	gl_FragColor = vec4(1.0f);
}