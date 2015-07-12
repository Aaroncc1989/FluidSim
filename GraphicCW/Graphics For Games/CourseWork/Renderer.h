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
	Matrix4 persProj;
	Matrix4 orthoProj;

	Shader* sceneShader;
	Shader* particleShader;
	Shader* curFlowShader;
	Shader* fluidShader;

	GLuint bufferFBO[2]; // FBO for our G- Buffer pass
	GLuint bufferColourTex[2]; // Albedo goes here
	GLuint bufferNormalTex; // Normals go here
	GLuint bufferDepthTex; // Depth goes here
};
