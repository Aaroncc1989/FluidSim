#include "Particles.h"
#include "ParticleCuda.cuh"

#include <cuda_runtime.h>
#include <helper_functions.h>
#include <helper_cuda.h>

#include <assert.h>
#include <math.h>
#include <memory.h>
#include <cstdio>
#include <cstdlib>
#include <algorithm>
#include <GL/glew.h>

Particles::Particles()
{
	initFlag = false;
	glGenVertexArrays(1, &arrayObject);
}


Particles::~Particles()
{
	assert(initFlag);

	delete[] pos;
	delete[] vel;

	freeArray(velGpu);
	freeArray(sortedPos);
	freeArray(sortedVel);
	freeArray(gridParticleHash);
	freeArray(gridParticleIndex);
	freeArray(cellStart);
	freeArray(cellEnd);

	unregisterGLBufferObject(m_cuda_colorvbo_resource);
	unregisterGLBufferObject(m_cuda_posvbo_resource);
	glDeleteBuffersARB(1, (const GLuint *)&posVbo);
	glDeleteBuffersARB(1, (const GLuint *)&colorVbo);
	glDeleteVertexArrays(1, &arrayObject);
}

void Particles::InitParticle()
{
	uint3 numCells = mparams.cellNum;

	for (int z = 0; z < numCells.z; z++)
	{
		for (int y = 0; y < numCells.y; y++)
		{
			for (int x = 0; x < numCells.x; x++)
			{
				int i = (z * numCells.y * numCells.x) + (y * numCells.x) + x;

				if (i < numParticles)
				{
					pos[i * 4] = (mparams.radius* 2.f * x *0.9f);
					pos[i * 4 + 1] = (mparams.radius* 2.f * y*0.9f);
					pos[i * 4 + 2] = (mparams.radius* 2.f * z *0.9f);
					pos[i * 4 + 3] = 1.0f;

					vel[i * 4] = 0;
					vel[i * 4 + 1] = 0;
					vel[i * 4 + 2] = 0;
					vel[i * 4 + 3] = 0;
				}
			}
		}
	}

	SetArray(POSITION, pos, 0, numParticles);
	SetArray(VELOCITY, vel, 0, numParticles);
}

void Particles::InitMemory()
{
	assert(!initFlag);

	pos = new float[numParticles * 4];
	vel = new float[numParticles * 4];
	//density = new float[numParticles];
	memset(pos, 0, numParticles * 4 * sizeof(float));
	memset(vel, 0, numParticles * 4 * sizeof(float));
	//memset(density, 0, numParticles * sizeof(float));

	cellStart = new uint[numParticles];
	cellEnd = new uint[numParticles];
	memset(cellStart, 0, numParticles*sizeof(uint));
	memset(cellEnd, 0, numParticles*sizeof(uint));

	uint memSize = sizeof(float) * 4 * numParticles;
	posVbo = CreateVBO(memSize,POSITION);
	registerGLBufferObject(posVbo, &m_cuda_posvbo_resource);

	allocateArray((void **)&velGpu, memSize);
	allocateArray((void **)&sortedPos, memSize);
	allocateArray((void **)&sortedVel, memSize);
	allocateArray((void **)&gridParticleHash, numParticles*sizeof(uint));
	allocateArray((void **)&gridParticleIndex, numParticles*sizeof(uint));
	allocateArray((void **)&cellStart, (mparams.wholeNumCells)*sizeof(uint));
	allocateArray((void **)&cellEnd, (mparams.wholeNumCells)*sizeof(uint));

	InitColor();
	setParameters(&mparams);
	initFlag = true;
}

void Particles::Init()
{
	glBindVertexArray(arrayObject);
	InitParams();
	InitMemory();
	InitParticle();
	glBindVertexArray(0);
}

uint Particles::CreateVBO(uint size, ParticleArray index)
{
	GLuint vbo;
	glGenBuffersARB(1, &vbo);
	glBindBufferARB(GL_ARRAY_BUFFER_ARB, vbo);
	glBufferDataARB(GL_ARRAY_BUFFER_ARB, size, 0, GL_DYNAMIC_DRAW_ARB);
	glVertexAttribPointer(index, 4, GL_FLOAT, GL_FALSE, 0, 0);
	glEnableVertexAttribArray(index);
	return (uint)vbo;
}

void Particles::InitColor()
{
	colorVbo = CreateVBO(numParticles * 4 * sizeof(float),COLOR);
	registerGLBufferObject(colorVbo, &m_cuda_colorvbo_resource);
	glBindBufferARB(GL_ARRAY_BUFFER_ARB, colorVbo);
	float *data = (float *)glMapBufferARB(GL_ARRAY_BUFFER_ARB, GL_WRITE_ONLY);
	float *ptr = data;
	for (uint i = 0; i<numParticles; i++)
	{
		*ptr++ = rand()/ (float)RAND_MAX;
		*ptr++ = rand() / (float)RAND_MAX;
		*ptr++ = rand() / (float)RAND_MAX;
		*ptr++ = 1.0f;
	}
	glUnmapBufferARB(GL_ARRAY_BUFFER_ARB);
}

void Particles::SetArray(ParticleArray array, const float *data, int start, int count)
{
	assert(initFlag);

	switch (array)
	{
	default:
	case POSITION:
	{
		unregisterGLBufferObject(m_cuda_posvbo_resource);
		glBindBufferARB(GL_ARRAY_BUFFER_ARB, posVbo);
		glBufferSubDataARB(GL_ARRAY_BUFFER_ARB, start * 4 * sizeof(float), count * 4 * sizeof(float), data);
		glBindBufferARB(GL_ARRAY_BUFFER_ARB, 0);
		registerGLBufferObject(posVbo, &m_cuda_posvbo_resource);
	}
	break;

	case VELOCITY:
		copyArrayToDevice(velGpu, data, start * 4 * sizeof(float), count * 4 * sizeof(float));
		break;
	}
}

void Particles::InitParams()
{
	mparams.radius = 0.5f;
	mparams.gridSize = make_uint3(64,64,256);
	mparams.cellSize = mparams.radius * 2.0f;
	mparams.cellNum = make_uint3(mparams.gridSize.x / mparams.cellSize, mparams.gridSize.y / mparams.cellSize, mparams.gridSize.z / mparams.cellSize);
	
	mparams.wholeNumCells = mparams.cellNum.x * mparams.cellNum.y*mparams.cellNum.z;
	mparams.worldPos = make_float3(0,0,0);
	mparams.colliderRadius = 0.9f * mparams.radius;
	mparams.gravity = make_float3(0.0f, -9.81f, 0.0f);
	mparams.timeStep = 0.001f;
	mparams.boundaryDamping = -0.5f;
	mparams.globalDamping = 1.0f;
	numParticles = 500000;

	//fluid coeffecient
	mparams.cutoffdist = 1.0f;
	mparams.stiffness = 500.0f;
	mparams.scale = 1.0f;
	mparams.restRHO = 1.7f;
	mparams.visalocityScale = 0.1f;
	mparams.tensionScale = 0.001f;
	mparams.spring = 200.0f;
	mparams.shear = 0.1f;
	mparams.damping = 0.0f;
	mparams.attraction = 0.0f;
}

void Particles::Update()
{
	assert(initFlag);
	float *dPos;
	dPos = (float *)mapGLBufferObject(&m_cuda_posvbo_resource);
	setParameters(&mparams);
	integrateSystem(dPos, velGpu, mparams.timeStep, numParticles);
	calcHash(gridParticleHash, gridParticleIndex,dPos,numParticles);
	sortParticles(gridParticleHash,gridParticleIndex,numParticles);
	reorderDataAndFindCellStart(cellStart,cellEnd,sortedPos,sortedVel,gridParticleHash,gridParticleIndex,dPos,velGpu,numParticles,mparams.wholeNumCells);
	simFluid(velGpu,sortedPos,sortedVel,gridParticleIndex,cellStart,cellEnd,numParticles,mparams.wholeNumCells);
	unmapGLBufferObject(m_cuda_posvbo_resource);
}

void Particles::DrawPoints()
{
	glBindVertexArray(arrayObject);
	glDrawArrays(GL_POINTS, 0, numParticles);
	glBindVertexArray(0);
}