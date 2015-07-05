#version 150 core
uniform int point;

in Vertex {
	vec2 texCoord;
	vec4 colour;
}IN;

out vec4 gl_FragColor[2];

void main(void){
	gl_FragColor[0] = IN.colour;
	gl_FragColor[1] = IN.colour;

	if (point == 1)
	{
		if (dot(gl_PointCoord - 0.5, gl_PointCoord - 0.5) > 0.25)
			discard;
		else   gl_FragColor[0] = IN.colour;
		gl_FragColor[1] = IN.colour;
	}
}