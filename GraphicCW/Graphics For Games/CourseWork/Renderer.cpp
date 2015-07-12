#include "Renderer.h"
Renderer::Renderer(Window & parent) : OGLRenderer(parent) {
	//camera = new Camera(0.0f, 0.0f, Vector3(
	//	RAW_WIDTH * HEIGHTMAP_X / 2.0f, 500, RAW_HEIGHT * HEIGHTMAP_Z));

	camera = new Camera(0.0f, 0.0f, Vector3(50, 50, -100));

	particle = new Particles();
	particle->Init();
	quad = Mesh::GenerateQuad();

	particleShader = new Shader("../../Shaders/particleVertex.glsl",
		"../../Shaders/particleFragment.glsl");
	curFlowShader = new Shader("../../Shaders/screenVertex.glsl",
		"../../Shaders/curFlowFragment.glsl");
	fluidShader = new Shader("../../Shaders/screenVertex.glsl",
		"../../Shaders/fluidFragment.glsl");
	sceneShader = new Shader("../../Shaders/TexturedVertex.glsl",
		"../../Shaders/TexturedFragment.glsl");

	if (!sceneShader->LinkProgram() 
		|| !particleShader->LinkProgram() 
		|| !curFlowShader->LinkProgram()
		|| !fluidShader->LinkProgram()) {
		return;
	}

	light = new Light(Vector3((RAW_HEIGHT * HEIGHTMAP_X / 2.0f),
		500.0f, (RAW_HEIGHT * HEIGHTMAP_Z / 2.0f)),
		Vector4(1, 1, 1, 1), (RAW_WIDTH * HEIGHTMAP_X) / 2.0f);

	persProj = Matrix4::Perspective(1.0f, 1000.f,(float)width / (float)height, 45.0f);
	orthoProj = Matrix4::Orthographic(-1, 1, 1, -1, 1, -1);

	GenerateBuffers();
	init = true;
}
Renderer ::~Renderer(void) {
	delete camera;
	delete light;
	delete particle;
	delete quad;

	glDeleteTextures(2, bufferColourTex);
	glDeleteTextures(1, &bufferDepthTex);
	glDeleteFramebuffers(2, bufferFBO);
	currentShader = 0;
}

void Renderer::UpdateScene(float msec) {
	camera->UpdateCamera(msec);
	viewMatrix = camera->BuildViewMatrix();
	particle->Update();
}

void Renderer::RenderScene() {
	glDepthMask(GL_TRUE);
	glEnable(GL_DEPTH_TEST);
	projMatrix = persProj;
	//Drawbg();
	DrawParticle();
	CurFlowSmoothing();
	DrawFluid();
	//PresentScene();
	SwapBuffers();
}

void Renderer::Drawbg()
{
	glBindFramebuffer(GL_FRAMEBUFFER, bufferFBO[0]);
	glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
	SetCurrentShader(particleShader);
	glUseProgram(currentShader->GetProgram());
	modelMatrix = Matrix4::Translation(Vector3(0,-50,0)) * Matrix4::Scale(Vector3(500, 500, 500)) * Matrix4::Rotation(90, Vector3(1.f, 0, 0));
	glUniform1i(glGetUniformLocation(currentShader->GetProgram(), "point"), 0);
	UpdateShaderMatrices();
	quad->Draw();
	glUseProgram(0);
}


void Renderer::DrawParticle()
{
	glBindFramebuffer(GL_FRAMEBUFFER, bufferFBO[0]);
	glClearColor(0, 0, 0, 1.0f);
	glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);
	//glEnable(GL_POINT_SPRITE_ARB);
	//glTexEnvi(GL_POINT_SPRITE_ARB, GL_COORD_REPLACE_ARB, GL_TRUE);
	glEnable(GL_VERTEX_PROGRAM_POINT_SIZE_NV);
	SetCurrentShader(particleShader);
	glUseProgram(currentShader->GetProgram());
	modelMatrix = Matrix4::Translation(Vector3()) * Matrix4::Scale(Vector3(50, 50, 50)) * Matrix4::Rotation(0, Vector3(1.f, 0, 0));
	glUniform1i(glGetUniformLocation(currentShader->GetProgram(), "point"), 1);
	glUniform1f(glGetUniformLocation(currentShader->GetProgram(), "pointRadius"), particle->mparams.radius);
	glUniform2f(glGetUniformLocation(currentShader->GetProgram(), "pixelSize"), 1.0f / width, 1.0f / height);

	UpdateShaderMatrices();
	particle->DrawPoints();
	glUseProgram(0);
	//glDisable(GL_POINT_SPRITE_ARB);
}

void Renderer::CurFlowSmoothing()
{
	SetCurrentShader(curFlowShader);
	glUseProgram(currentShader->GetProgram());
	glUniform2f(glGetUniformLocation(currentShader->GetProgram(), "pixelSize"), 1.0f / width, 1.0f / height);
	glUniformMatrix4fv(glGetUniformLocation(currentShader->GetProgram(), "projMatrix"), 1, false, (float*)&projMatrix);
	glDisable(GL_DEPTH_TEST);
	int pingpong = 0;
	int smoothingIterations = 60;
	for (int i = 0; i < smoothingIterations; i++)
	{
		glBindFramebuffer(GL_FRAMEBUFFER, 0);
		glBindFramebuffer(GL_FRAMEBUFFER,bufferFBO[1-pingpong]);
		quad->SetTexture(bufferColourTex[pingpong]);
		quad->Draw();
		pingpong = 1 - pingpong;
	}
	glEnable(GL_DEPTH_TEST);
}

void Renderer::DrawFluid()
{
	glBindFramebuffer(GL_FRAMEBUFFER, 0);
	glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);
	SetCurrentShader(fluidShader);
	glUseProgram(currentShader->GetProgram());
	glUniform2f(glGetUniformLocation(currentShader->GetProgram(), "pixelSize"), 1.0f / width, 1.0f / height);
	glUniformMatrix4fv(glGetUniformLocation(currentShader->GetProgram(), "projMatrix"), 1, false, (float*)&projMatrix);
	glUniformMatrix4fv(glGetUniformLocation(currentShader->GetProgram(), "modelViewMatrix"), 1, false, (float*)&(viewMatrix * modelMatrix));

	quad->SetTexture(bufferColourTex[0]);
	quad->Draw();
	glUseProgram(0);
}


void Renderer::PresentScene()
{
	glBindFramebuffer(GL_FRAMEBUFFER, 0);
	glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
	SetCurrentShader(sceneShader);

	glUseProgram(currentShader->GetProgram());
	projMatrix = orthoProj;
	modelMatrix.ToIdentity();
	viewMatrix.ToIdentity();

	glUniform2f(glGetUniformLocation(currentShader->GetProgram(),
		"pixelSize"), 1.0f / width, 1.0f / height);

	UpdateShaderMatrices();
	quad->SetTexture(bufferColourTex[0]);
	quad->Draw();
	glUseProgram(0);
}


void Renderer::GenerateBuffers()
{
	glGenFramebuffers(2, bufferFBO);
	GenerateScreenTexture(bufferDepthTex, true);

	for (int i = 0; i < 2; i++)
	{
		GenerateScreenTexture(bufferColourTex[i]);
		glBindFramebuffer(GL_FRAMEBUFFER, bufferFBO[i]);
		glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
			GL_TEXTURE_2D, bufferColourTex[i], 0);
		glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT,
			GL_TEXTURE_2D, bufferDepthTex, 0);
	}

	if (glCheckFramebufferStatus(GL_FRAMEBUFFER) !=
		GL_FRAMEBUFFER_COMPLETE) {
		return;
	}
	glBindFramebuffer(GL_FRAMEBUFFER, 0);
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