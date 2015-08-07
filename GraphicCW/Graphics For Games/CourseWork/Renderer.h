#pragma once
#include "Particles.h"
#include "../../nclgl/OGLRenderer.h"
#include "../../nclgl/Camera.h"
#include "../../nclgl/HeightMap.h"
#include "../../nclgl/OBJMesh.h"

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
	void DrawFluid();

	void PresentScene();
	void Drawbg();

protected:
	Particles* particle;
	Camera * camera;
	Light * light;
	Mesh* quad;
	Mesh* cube;
	unsigned int quadtxt;

	Shader* sceneShader;
	Shader* particleShader;
	Shader* curFlowShader;
	Shader* fluidShader;
	Shader* thickness;

	GLuint bufferFBO[3]; // FBO for our G- Buffer pass
	GLuint bufferColourTex[3]; // Albedo goes here
	GLuint bufferDepthTex; // Depth goes here

	bool smoothSwitch;
};
