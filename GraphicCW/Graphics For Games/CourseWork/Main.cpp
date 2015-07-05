#pragma comment(lib, "nclgl.lib")

#include "../../nclgL/window.h"
#include "Renderer.h"
#include "ParticleCuda.cuh"
#include <GL/freeglut.h>

extern "C" void cudaGLInit(int argc, char **argv);

int main(int argc, char **argv) {
	Window w("FluidSimulation!", 1280, 960, false);
	if (!w.HasInitialised()) {
		return -1;
	}

	cudaGLInit(argc,argv);

	Renderer renderer(w);
	if (!renderer.HasInitialised()) {
		return -1;
	}

	w.LockMouseToWindow(true);
	w.ShowOSPointer(false);

	while (w.UpdateWindow() && !Window::GetKeyboard()->KeyDown(KEYBOARD_ESCAPE)){
		renderer.UpdateScene(w.GetTimer()->GetTimedMS());
		renderer.RenderScene();
	}

	return 0;
}