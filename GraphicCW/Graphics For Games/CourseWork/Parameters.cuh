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

	uint gridSize;				//per axis
	float cellSize;
	uint cellNum;				//per axis
	uint wholeNumCells;
	float3 worldPos;

	float spring;
	float damping;
	float shear;
	float attraction;
	float boundaryDamping;
};

