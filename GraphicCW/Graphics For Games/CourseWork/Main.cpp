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
	float timesum = 0;
	int fps = 0;
	while (w.UpdateWindow() && !Window::GetKeyboard()->KeyDown(KEYBOARD_ESCAPE)){
		float t = w.GetTimer()->GetTimedMS();
		timesum += t;
		fps += 1;
		renderer.UpdateScene(t);
		renderer.RenderScene();
		if (timesum >= 1000.0f)
		{
			w.SetWindowTitle("FluidSimulation! fps:"+std::to_string(fps));
			timesum -= 1000.0f;
			fps = 0;
		}
		
	}

	return 0;
}