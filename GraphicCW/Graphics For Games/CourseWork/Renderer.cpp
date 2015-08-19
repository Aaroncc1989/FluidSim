#include "Renderer.h"
Renderer::Renderer(Window & parent) : OGLRenderer(parent) {
	camera = new Camera(0.0f, 0.0f, Vector3(
		RAW_WIDTH * HEIGHTMAP_X / 2.0f, 500, RAW_HEIGHT * HEIGHTMAP_Z/3.0f));

	//camera = new Camera(0.0f, 0.0f, Vector3(50, 50, -100));

	particle = new Particles();
	particle->Init();
	quad = Mesh::GenerateQuad();
	ground = Mesh::GenerateQuad();
	solidSphere = new OBJMesh("../../Meshes/sphere.obj");

	particleShader = new Shader("../../Shaders/particleVertex.glsl",
		"../../Shaders/particleFragment.glsl");
	thickness = new Shader("../../Shaders/thicknessVertex.glsl",
		"../../Shaders/thicknessFragment.glsl");
	curFlowShader = new Shader("../../Shaders/curFlowVertex.glsl",
		"../../Shaders/curFlowFragment.glsl");
	fluidShader = new Shader("../../Shaders/fluidVertex.glsl",
		"../../Shaders/fluidFragment.glsl");
	sceneShader = new Shader("../../Shaders/TexturedVertex.glsl",
		"../../Shaders/TexturedFragment.glsl");
	bilateralFilter = new Shader("../../Shaders/bilateralFilterVertex.glsl", 
		"../../Shaders/bilateralFilterFragment.glsl");

	quadtxt = SOIL_load_OGL_texture(TEXTUREDIR"ground.jpg",
		SOIL_LOAD_AUTO, SOIL_CREATE_NEW_ID, SOIL_FLAG_MIPMAPS);
	spheretxt = SOIL_load_OGL_texture(TEXTUREDIR"leaf.jpg", 
		SOIL_LOAD_AUTO, SOIL_CREATE_NEW_ID, 0);
	ground->SetTexture(quadtxt);
	solidSphere->SetTexture(spheretxt);

	if (!sceneShader->LinkProgram()
		|| !thickness->LinkProgram()
		|| !particleShader->LinkProgram()
		|| !curFlowShader->LinkProgram()
		|| !fluidShader->LinkProgram()
		|| !bilateralFilter->LinkProgram()){
		return;
	}

	light = new Light(Vector3((RAW_HEIGHT * HEIGHTMAP_X / 2.0f),
		500.0f, (RAW_HEIGHT * HEIGHTMAP_Z / 2.0f)),
		Vector4(1, 1, 1, 1), (RAW_WIDTH * HEIGHTMAP_X) / 2.0f);

	projMatrix = Matrix4::Perspective(1.0f, 10000.f, (float)width / (float)height, 45.0f);

	GenerateBuffers();
	init = true;
	smoothSwitch = false;
	tmp = 120;
}
Renderer ::~Renderer(void) {
	delete camera;
	delete light;
	delete particle;
	delete quad;
	delete ground;
	delete solidSphere;

	delete particleShader;
	delete thickness;
	delete curFlowShader;
	delete fluidShader;
	delete sceneShader;

	glDeleteTextures(4, bufferColourTex);
	glDeleteTextures(4, bufferDepthTex);
	glDeleteFramebuffers(4, bufferFBO);
	currentShader = 0;
}

void Renderer::UpdateScene(float msec) {
	camera->UpdateCamera(msec);
	viewMatrix = camera->BuildViewMatrix();
	if (Window::GetKeyboard()->KeyTriggered(KEYBOARD_R))
	{
		particle->InitParticle();
	}
	if (Window::GetKeyboard()->KeyTriggered(KEYBOARD_C))
	{
		smoothSwitch = !smoothSwitch;
	}
	bool stop = false;
	if (Window::GetKeyboard()->KeyTriggered(KEYBOARD_1))
	{
		
	}

	particle->Update();
}

void Renderer::RenderScene() {
	glDepthMask(GL_TRUE);
	Drawbg();
	DrawParticle();
	RendThickness();
	BilateralFilter();
	CurFlowSmoothing();
	DrawFluid();
	SwapBuffers();
}

void Renderer::Drawbg()
{
	glBindFramebuffer(GL_FRAMEBUFFER, 0);
	glClearColor(0.2f, 0.2f, 0.2f, 1.0f);
	glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
	glEnable(GL_DEPTH_TEST);
	SetCurrentShader(sceneShader);
	glUseProgram(currentShader->GetProgram());
	modelMatrix = Matrix4::Translation(Vector3(0, -5, 0)) * Matrix4::Scale(Vector3(320, 500, 1280)) * Matrix4::Rotation(90, Vector3(1.f, 0, 0));
	UpdateShaderMatrices();
	ground->Draw();
	//build solid modelMatrix
	float* solidPos = new float[4];
	memset(solidPos, 0, sizeof(float)* 4);
	particle->GetSolidPos(solidPos);
	Matrix4 trans;
	trans.SetPositionVector(Vector3(solidPos[0], solidPos[1], solidPos[2]));
	delete[]solidPos;
	modelMatrix = Matrix4::Translation(Vector3(-320, 0, -1280)) * Matrix4::Scale(Vector3(10, 10, 10)) *  Matrix4::Rotation(0, Vector3(1.f, 0, 0));
	modelMatrix = modelMatrix * trans * Matrix4::Scale(Vector3(10, 10, 10));

	UpdateShaderMatrices();
	solidSphere->Draw();
	glUseProgram(0);
}


void Renderer::DrawParticle()
{
	glBindFramebuffer(GL_FRAMEBUFFER, bufferFBO[PARTICLE]);
	glClearColor(0, 0, 0, 1.0f);
	glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
	glEnable(GL_DEPTH_TEST);
	glEnable(GL_VERTEX_PROGRAM_POINT_SIZE_NV);
	SetCurrentShader(particleShader);
	glUseProgram(currentShader->GetProgram());
	modelMatrix = Matrix4::Translation(Vector3(-320, 0, -1280)) * Matrix4::Scale(Vector3(10, 10, 10)) *  Matrix4::Rotation(0, Vector3(1.f, 0, 0));
	glUniform1i(glGetUniformLocation(currentShader->GetProgram(), "point"), 1);
	glUniform1f(glGetUniformLocation(currentShader->GetProgram(), "pointRadius"), particle->mparams.radius);
	glUniform2f(glGetUniformLocation(currentShader->GetProgram(), "pixelSize"), 1.0f / width, 1.0f / height);

	UpdateShaderMatrices();
	particle->DrawPoints();
	glUseProgram(0);
}

void Renderer::RendThickness()
{
	glBindFramebuffer(GL_FRAMEBUFFER, bufferFBO[THICKNESS]);
	glClearColor(0, 0, 0, 1.0f);
	glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);
	glEnable(GL_VERTEX_PROGRAM_POINT_SIZE_NV);
	glEnable(GL_BLEND);
	glBlendFunc(GL_ONE, GL_ONE);
	glDisable(GL_DEPTH_TEST);
	SetCurrentShader(thickness);
	glUseProgram(currentShader->GetProgram());
	modelMatrix = Matrix4::Translation(Vector3(-320, 0, -1280)) * Matrix4::Scale(Vector3(10, 10, 10)) *  Matrix4::Rotation(0, Vector3(1.f, 0, 0));
	glUniform1i(glGetUniformLocation(currentShader->GetProgram(), "point"), 1);
	glUniform1f(glGetUniformLocation(currentShader->GetProgram(), "pointRadius"), particle->mparams.radius);
	glUniform2f(glGetUniformLocation(currentShader->GetProgram(), "pixelSize"), 1.0f / width, 1.0f / height);

	UpdateShaderMatrices();
	particle->DrawPoints();
	glUseProgram(0);
	glDisable(GL_BLEND);
}

void Renderer::BilateralFilter()
{
	SetCurrentShader(bilateralFilter);
	glUseProgram(currentShader->GetProgram());

	glBindFramebuffer(GL_FRAMEBUFFER, bufferFBO[1]);
	glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);
	glUniform1f(glGetUniformLocation(currentShader->GetProgram(), "pixel"), 1.0f / width);
	glUniform2f(glGetUniformLocation(currentShader->GetProgram(), "blurDir"), 1.0f, 0);
	quad->SetTexture(bufferColourTex[THICKNESS]);
	quad->Draw();

	glBindFramebuffer(GL_FRAMEBUFFER, bufferFBO[THICKNESS]);
	glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);
	glUniform1f(glGetUniformLocation(currentShader->GetProgram(), "pixel"), 1.0f / height);
	glUniform2f(glGetUniformLocation(currentShader->GetProgram(), "blurDir"), 0, 1.0f);
	quad->SetTexture(bufferColourTex[1]);
	quad->Draw();

	glUseProgram(0);
}

void Renderer::CurFlowSmoothing()
{
	if (!smoothSwitch) return;
	SetCurrentShader(curFlowShader);
	glUseProgram(currentShader->GetProgram());
	glUniform2f(glGetUniformLocation(currentShader->GetProgram(), "pixelSize"), 1.0f / width, 1.0f / height);
	glUniformMatrix4fv(glGetUniformLocation(currentShader->GetProgram(), "projMatrix"), 1, false, (float*)&projMatrix);
	glDisable(GL_DEPTH_TEST);
	int pingpong = 0;
	int smoothingIterations = tmp;	
	quad->SetTexture(bufferColourTex[PARTICLE]);
	for (int i = 0; i < smoothingIterations; i++)
	{
		glBindFramebuffer(GL_FRAMEBUFFER, bufferFBO[1 - pingpong]);
		glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);
		quad->Draw();
		pingpong = 1 - pingpong;		
		quad->SetTexture(bufferColourTex[pingpong]);
	}
	glUseProgram(0);
}

void Renderer::DrawFluid()
{
	glBindFramebuffer(GL_FRAMEBUFFER, 0);
	//glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);
	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glEnable(GL_DEPTH_TEST);
	SetCurrentShader(fluidShader);
	glUseProgram(currentShader->GetProgram());
	glUniform2f(glGetUniformLocation(currentShader->GetProgram(), "pixelSize"), 1.0f / width, 1.0f / height);
	glUniformMatrix4fv(glGetUniformLocation(currentShader->GetProgram(), "projMatrix"), 1, false, (float*)&projMatrix);
	glUniformMatrix4fv(glGetUniformLocation(currentShader->GetProgram(), "viewMatrix"), 1, false, (float*)&viewMatrix);
	glUniformMatrix4fv(glGetUniformLocation(currentShader->GetProgram(), "modelMatrix"), 1, false, (float*)&modelMatrix);

	glActiveTexture(GL_TEXTURE2);
	glBindTexture(GL_TEXTURE_2D, bufferColourTex[THICKNESS]);
	glUniform1i(glGetUniformLocation(currentShader->GetProgram(), "thicknessTex"), 2);

	glActiveTexture(GL_TEXTURE3);
	glBindTexture(GL_TEXTURE_2D, bufferDepthTex[PARTICLE]);
	glUniform1i(glGetUniformLocation(currentShader->GetProgram(), "pixelDepthTex"), 3);

	if (smoothSwitch) quad->SetTexture(bufferColourTex[SMOOTH0]);
	else quad->SetTexture(bufferColourTex[PARTICLE]);

	quad->Draw();
	glUseProgram(0);
	glDisable(GL_BLEND);
}

void Renderer::GenerateBuffers()
{
	glGenFramebuffers(4, bufferFBO);

	for (int i = 0; i < 4; i++)
	{
		GenerateScreenTexture(bufferColourTex[i]);	
		GenerateScreenTexture(bufferDepthTex[i], true);
		glBindFramebuffer(GL_FRAMEBUFFER, bufferFBO[i]);
		glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
			GL_TEXTURE_2D, bufferColourTex[i], 0);
		glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT,
			GL_TEXTURE_2D, bufferDepthTex[i], 0);
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
		depth ? GL_DEPTH_COMPONENT24 : GL_R32F,
		width, height, 0,
		depth ? GL_DEPTH_COMPONENT : GL_RED,
		depth ? GL_UNSIGNED_BYTE : GL_FLOAT, NULL);

	glBindTexture(GL_TEXTURE_2D, 0);
}