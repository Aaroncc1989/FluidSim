#version 150 core

uniform sampler2D diffuseTex ;
uniform float pixel;
uniform vec2 blurDir;

in vec2 coords;
out float bdepth;

void main (void){
	float depth = texture(diffuseTex,coords);
	//if (depth == 0){ discard; }
	float sum = 0;
	float wsum = 0;
	float radius = 20.0f;
	float blurScale = 5.0f;

	for (float x = -radius; x <= radius; x += 1.0f)
	{
			float sample = texture(diffuseTex, coords + x * blurDir * pixel);	
			float v = x / blurScale;
			float w = exp(-v*v/2.0f);
			sum += sample*w;
			wsum += w;
	}

	if (wsum > 0.0)
	{
		sum /= wsum;
	}
	bdepth = sum;
}