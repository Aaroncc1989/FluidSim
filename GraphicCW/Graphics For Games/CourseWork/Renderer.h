#pragma once
#include "Particles.h"
#include "../../nclgl/OGLRenderer.h"
#include "../../nclgl/Camera.h"
#include "../../nclgl/HeightMap.h"

class Renderer : public OGLRenderer {
public:
	Renderer(Window & parent);
	virtual ~Renderer(void);

	virtual void RenderScene();
	virtual void UpdateScene(float msec);
	void GenerateScreenTexture(GLuint &into, bool depth = false);
	void GenerateBuffers();

	void DrawParticle();
	void CurFlowSmoothing();
	void DrawFluid();

	void PresentScene();
	void Drawbg();

protected:
	Particles* particle;
	Camera * camera;
	Light * light;
	Mesh* quad;
	unsigned int quadtxt;

	Shader* sceneShader;
	Shader* particleShader;
	Shader* curFlowShader;
	Shader* fluidShader;

	GLuint bufferFBO[2]; // FBO for our G- Buffer pass
	GLuint bufferColourTex; // Albedo goes here
	GLuint bufferDepthTex[2]; // Depth goes here
};
