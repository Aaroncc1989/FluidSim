 #version 150 core

 uniform sampler2D diffuseTex;
 uniform int useTexture;

 in Vertex{
 vec2 texCoord;
 vec4 colour;
 vec3 normal;
 }IN;

 out vec4 gl_FragColor;

 void main(void){
	 gl_FragColor = IN.colour;
	 if (useTexture > 0) {
		 gl_FragColor *= texture(diffuseTex, IN.texCoord);
	 }

	 //gl_FragColor = vec4(IN.normal,1.0f);

 }