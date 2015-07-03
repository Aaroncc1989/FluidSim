#version 150 core
uniform int point;

in Vertex {
vec4 colour ;
}IN;

out vec4 gl_FragColor;

void main(void){
	gl_FragColor = IN.colour;
	if (point == 1)
	{
		if (dot(gl_PointCoord - 0.5, gl_PointCoord - 0.5) > 0.25)
			discard;
		else   gl_FragColor = IN.colour;
	}
}