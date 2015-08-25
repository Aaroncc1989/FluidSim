#pragma once
#include "Parameters.cuh"
#include "../../nclgl/Quaternion.h"

enum ParticleArray
{
	POSITION,
	COLOR,
	VELOCITY
};

class Particles
{
public:
	Particles();
	~Particles();

	void Init();
	void InitParticle();
	void InitMemory();
	void InitParams();

	void DrawPoints();
	void Update();
	uint CreateVBO(uint size,ParticleArray index);
	void InitColor();
	void SetArray(ParticleArray array, const float *data, int start, int count);
	SimParams mparams;

	void InitSolid();
	Matrix4 BuildTransform();
	void CheckEdges(float* pos,float* vel);

protected:
	//particle attribute
	int numParticles;

	float* pos;
	float* color;
	float* vel;
	float* density;
	float* normal;
	float* textureCoord;

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

	//solid data
	Quaternion orientation;
	float* solidPos;
	float* solidVel;
	float* solidPosGpu;
	float* solidVelGpu;
	float* buoyancy;
	float* buoyancyGpu;
	float* buoyancyAng;
	float* buoyancyAngGpu;
};

