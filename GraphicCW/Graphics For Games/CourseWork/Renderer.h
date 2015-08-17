#pragma once
#include "Particles.h"
#include "../../nclgl/OGLRenderer.h"
#include "../../nclgl/Camera.h"
#include "../../nclgl/HeightMap.h"
#include "../../nclgl/OBJMesh.h"

enum FBOINDEX
{
	SMOOTH0,
	SMOOTH1,
	PARTICLE,
	THICKNESS
};

class Renderer : public OGLRenderer {
public:
	Renderer(Window & parent);
	virtual ~Renderer(void);

	virtual void RenderScene();
	virtual void UpdateScene(float msec);
	void GenerateScreenTexture(GLuint &into, bool depth = false);
	void GenerateBuffers();

	void DrawParticle();
	void RendThickness();
	void CurFlowSmoothing();
	void BilateralFilter();
	void DrawFluid();

	void PresentScene();
	void Drawbg();

protected:
	Particles* particle;
	Camera * camera;
	Light * light;
	Mesh* quad;
	Mesh* ground;
	Mesh* solidSphere;
	unsigned int quadtxt;
	unsigned int spheretxt;
	int tmp;

	Shader* sceneShader;
	Shader* particleShader;
	Shader* curFlowShader;
	Shader* fluidShader;
	Shader* thickness;
	Shader* bilateralFilter;

	GLuint bufferFBO[4]; // FBO for our G-Buffer pass
	GLuint bufferColourTex[4]; // Albedo goes here
	GLuint bufferDepthTex[4]; // Depth goes here

	bool smoothSwitch;
};
