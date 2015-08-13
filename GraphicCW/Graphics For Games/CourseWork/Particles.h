#pragma once
#include "Parameters.cuh"

class Particles
{
public:
	Particles();
	~Particles();

	enum ParticleArray
	{
		POSITION,
		COLOR,
		VELOCITY
	};

	void Init();
	void InitParticle();
	void InitMemory();
	void InitParams();

	void DrawPoints();
	void Update();
	void AddSphere();
	uint CreateVBO(uint size,ParticleArray index);
	void InitColor();
	void SetArray(ParticleArray array, const float *data, int start, int count);
	SimParams mparams;

protected:
	//particle attribute
	int numParticles;
	

	float* pos;
	float* color;
	float* vel;
	float* density;
	float* normal;
	float* textureCoord;

	float4* p;
	//gpu data
	float* velGpu;
	float* posGpu;
	float* sortedPos;
	float* sortedVel;
	uint* gridParticleHash;
	uint* gridParticleIndex;
	uint* cellStart;
	uint* cellEnd;

	uint posVbo;
	uint colorVbo;
	uint arrayObject;

	bool initFlag;
	struct cudaGraphicsResource *m_cuda_posvbo_resource; // handles OpenGL-CUDA exchange
	struct cudaGraphicsResource *m_cuda_colorvbo_resource; // handles OpenGL-CUDA exchange
};

