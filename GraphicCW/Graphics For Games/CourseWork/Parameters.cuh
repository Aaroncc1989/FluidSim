#pragma once
#include "vector_types.h"
typedef unsigned int uint;

struct SimParams
{
	float3 colliderPos;
	float  colliderRadius;

	float3 gravity;
	float globalDamping;
	float radius;
	float timeStep;

	uint3 gridSize;				//per axis
	float cellSize;
	uint3 cellNum;				//per axis
	uint wholeNumCells;
	float3 worldPos;

	float damping;
	float boundaryDamping;
	float shear;
	float spring;
	float attraction;

	float cutoffdist;
	float stiffness;
	float scale;
	float restRHO;
	float visalocityScale;
	float tensionScale;
};

