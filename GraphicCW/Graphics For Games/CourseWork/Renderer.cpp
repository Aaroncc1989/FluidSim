#include "Renderer.h"
Renderer::Renderer(Window & parent) : OGLRenderer(parent) {
	//camera = new Camera(0.0f, 0.0f, Vector3(
	//	RAW_WIDTH * HEIGHTMAP_X / 2.0f, 500, RAW_HEIGHT * HEIGHTMAP_Z));

	camera = new Camera(0.0f, 0.0f, Vector3(50, 50, -100));

	particle = new Particles();
	particle->Init();
	quad = Mesh::GenerateQuad();

	currentShader = new Shader("../../Shaders/basicVertex.glsl",
		"../../Shaders/colourFragment.glsl");

	if (!currentShader->LinkProgram()) {
		return;
	}

	//light = new Light(Vector3((RAW_HEIGHT * HEIGHTMAP_X / 2.0f),
	//	500.0f, (RAW_HEIGHT * HEIGHTMAP_Z / 2.0f)),
	//	Vector4(1, 1, 1, 1), (RAW_WIDTH * HEIGHTMAP_X) / 2.0f);

	projMatrix = Matrix4::Perspective(1.0f, 1000.f,
		(float)width / (float)height, 45.0f);

	init = true;
}
Renderer ::~Renderer(void) {
	delete camera;
	//delete light;
	delete particle;
	delete quad;
}

void Renderer::UpdateScene(float msec) {
	camera->UpdateCamera(msec);
	viewMatrix = camera->BuildViewMatrix();
	particle->Update();
}

void Renderer::RenderScene() {
	glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);
	glDepthMask(GL_TRUE);
	glEnable(GL_DEPTH_TEST);
	glUseProgram(currentShader->GetProgram());
	glUniform1i(glGetUniformLocation(currentShader->GetProgram(), "point"), 0);
	modelMatrix = Matrix4::Translation(Vector3(0, -50, 0)) * Matrix4::Scale(Vector3(200, 100, 200)) * Matrix4::Rotation(90, Vector3(1.f, 0, 0));
	UpdateShaderMatrices();
	quad->Draw();

	//glEnable(GL_POINT_SPRITE_ARB);
	//glTexEnvi(GL_POINT_SPRITE_ARB, GL_COORD_REPLACE_ARB, GL_TRUE);
	//glEnable(GL_VERTEX_PROGRAM_POINT_SIZE_NV);
	glPointSize(10.0f);
	glHint(GL_POINT_SMOOTH_HINT, GL_NICEST);
	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	modelMatrix = Matrix4::Translation(Vector3()) * Matrix4::Scale(Vector3(50,50,50)) * Matrix4::Rotation(0,Vector3(1.f,0,0));
	glUniform1i(glGetUniformLocation(currentShader->GetProgram(), "point"), 1);
	//glUniform1f(glGetUniformLocation(currentShader->GetProgram(), "pointRadius"), 10);
	UpdateShaderMatrices();
	particle->DrawPoints();	

	glUseProgram(0);
	//glDisable(GL_POINT_SPRITE_ARB);
	SwapBuffers();
}
