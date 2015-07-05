#include "Renderer.h"
Renderer::Renderer(Window & parent) : OGLRenderer(parent) {
	//camera = new Camera(0.0f, 0.0f, Vector3(
	//	RAW_WIDTH * HEIGHTMAP_X / 2.0f, 500, RAW_HEIGHT * HEIGHTMAP_Z));

	camera = new Camera(0.0f, 0.0f, Vector3(50, 50, -100));

	particle = new Particles();
	particle->Init();
	quad = Mesh::GenerateQuad();

	sceneShader = new Shader("../../Shaders/TexturedVertex.glsl",
		"../../Shaders/TexturedFragment.glsl");
	postShader = new Shader("../../Shaders/postVertex.glsl",
		"../../Shaders/postFragment.glsl");

	if (!sceneShader->LinkProgram() || !postShader->LinkProgram()) {
		return;
	}

	light = new Light(Vector3((RAW_HEIGHT * HEIGHTMAP_X / 2.0f),
		500.0f, (RAW_HEIGHT * HEIGHTMAP_Z / 2.0f)),
		Vector4(1, 1, 1, 1), (RAW_WIDTH * HEIGHTMAP_X) / 2.0f);

	GenerateBuffers();
	init = true;
}
Renderer ::~Renderer(void) {
	delete camera;
	delete light;
	delete particle;
	delete quad;

	glDeleteTextures(1, &bufferColourTex);
	glDeleteTextures(1, &bufferNormalTex);
	glDeleteTextures(1, &bufferDepthTex);
	glDeleteFramebuffers(1, &bufferFBO);
	currentShader = 0;
}

void Renderer::UpdateScene(float msec) {
	camera->UpdateCamera(msec);
	viewMatrix = camera->BuildViewMatrix();
	particle->Update();
}

void Renderer::RenderScene() {
	
	//glDepthMask(GL_TRUE);
	//glEnable(GL_DEPTH_TEST);
	projMatrix = Matrix4::Perspective(1.0f, 1000.f,
		(float)width / (float)height, 45.0f);
	//glUseProgram(currentShader->GetProgram());
	//glUniform1i(glGetUniformLocation(currentShader->GetProgram(), "point"), 0);
	//modelMatrix = Matrix4::Translation(Vector3(0, -52, 0)) * Matrix4::Scale(Vector3(200, 100, 200)) * Matrix4::Rotation(90, Vector3(1.f, 0, 0));
	//UpdateShaderMatrices();
	//quad->Draw();
	DrawScene();
	PresentScene();
	SwapBuffers();
}

void Renderer::GenerateScreenTexture(GLuint & into, bool depth)
{
	glGenTextures(1, &into);
	glBindTexture(GL_TEXTURE_2D, into);

	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);

	glTexImage2D(GL_TEXTURE_2D, 0,
		depth ? GL_DEPTH_COMPONENT24 : GL_RGBA8,
		width, height, 0,
		depth ? GL_DEPTH_COMPONENT : GL_RGBA,
		GL_UNSIGNED_BYTE, NULL);

	glBindTexture(GL_TEXTURE_2D, 0);
}

void Renderer::GenerateBuffers()
{
	GLenum buffers[2];
	buffers[0] = GL_COLOR_ATTACHMENT0;
	buffers[1] = GL_COLOR_ATTACHMENT1;

	glGenFramebuffers(1, &bufferFBO);

	GenerateScreenTexture(bufferDepthTex, true);
	GenerateScreenTexture(bufferColourTex);
	GenerateScreenTexture(bufferNormalTex);

	glBindFramebuffer(GL_FRAMEBUFFER, bufferFBO);
	glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
		GL_TEXTURE_2D, bufferColourTex, 0);
	glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT1,
		GL_TEXTURE_2D, bufferNormalTex, 0);
	glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT,
		GL_TEXTURE_2D, bufferDepthTex, 0);
	glDrawBuffers(2, buffers);

	if (glCheckFramebufferStatus(GL_FRAMEBUFFER) !=
		GL_FRAMEBUFFER_COMPLETE) {
		return;
	}
	glBindFramebuffer(GL_FRAMEBUFFER, 0);
}

void Renderer::DrawScene()
{
	glBindFramebuffer(GL_FRAMEBUFFER, bufferFBO);
	glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
	//glEnable(GL_POINT_SPRITE_ARB);
	//glTexEnvi(GL_POINT_SPRITE_ARB, GL_COORD_REPLACE_ARB, GL_TRUE);
	glEnable(GL_VERTEX_PROGRAM_POINT_SIZE_NV);
	SetCurrentShader(postShader);
	glUseProgram(currentShader->GetProgram());
	modelMatrix = Matrix4::Translation(Vector3()) * Matrix4::Scale(Vector3(50, 50, 50)) * Matrix4::Rotation(0, Vector3(1.f, 0, 0));
	glUniform1i(glGetUniformLocation(currentShader->GetProgram(), "point"), 1);
	glUniform1f(glGetUniformLocation(currentShader->GetProgram(), "pointRadius"), particle->mparams.radius);
	//textureMatrix.ToIdentity();
	UpdateShaderMatrices();

	particle->DrawPoints();
	glUseProgram(0);
	//glDisable(GL_POINT_SPRITE_ARB);
}

void Renderer::PresentScene()
{
	glBindFramebuffer(GL_FRAMEBUFFER, 0);
	glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
	SetCurrentShader(sceneShader);

	glUseProgram(currentShader->GetProgram());
	projMatrix = Matrix4::Orthographic(-1, 1, 1, -1, 1, -1);
	modelMatrix.ToIdentity();
	viewMatrix.ToIdentity();

	glUniform1i(glGetUniformLocation(currentShader->GetProgram(), "useTexture"), 1);
	glUniform1i(glGetUniformLocation(currentShader->GetProgram(), "depTex"), 2);
	glActiveTexture(GL_TEXTURE2);
	glBindTexture(GL_TEXTURE_2D, bufferDepthTex);

	UpdateShaderMatrices();
	quad->SetTexture(bufferColourTex);
	quad->Draw();
	glUseProgram(0);
}