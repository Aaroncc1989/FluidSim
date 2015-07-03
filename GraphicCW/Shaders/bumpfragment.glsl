# version 150 core
uniform sampler2D diffuseTex ;
uniform sampler2D bumpTex ; // New !

uniform vec3 cameraPos ;
uniform vec4 lightColour ;
uniform vec3 lightPos ;
uniform float lightRadius ;

in Vertex {
vec3 colour ;
vec2 texCoord ;
vec3 normal ;
vec3 tangent ; // New !
vec3 binormal ; // New !
vec3 worldPos ;
}IN;

out vec4 gl_FragColor;
 void main ( void ) {
 vec4 diffuse = texture(diffuseTex , IN.texCoord );
 // New !
 mat3 TBN = mat3 (IN.tangent , IN.binormal , IN.normal );
 // New !
 vec3 normal = normalize (TBN*( texture ( bumpTex,
 IN.texCoord ).rgb * 2.0 - 1.0));

  vec3 incident = normalize ( lightPos - IN.worldPos );
 float lambert = max (0.0 , dot ( incident , normal )); // Different !

 float dist = length ( lightPos - IN. worldPos );
 float atten = 1.0 - clamp ( dist / lightRadius , 0.0 , 1.0);

 vec3 viewDir = normalize ( cameraPos - IN. worldPos );
 vec3 halfDir = normalize ( incident + viewDir );

 float rFactor = max (0.0 , dot ( halfDir , normal )); // Different !
 float sFactor = pow ( rFactor , 33.0 );

 vec3 colour = ( diffuse.rgb * lightColour.rgb );
 colour += ( lightColour.rgb * sFactor ) * 0.33;
 gl_FragColor = vec4 ( colour * atten * lambert , diffuse.a);
 gl_FragColor.rgb += ( diffuse.rgb * lightColour.rgb ) * 0.1;
 }