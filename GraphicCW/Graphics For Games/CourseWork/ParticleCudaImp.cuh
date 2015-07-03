#ifndef _PARTICLES_KERNEL_H_
#define _PARTICLES_KERNEL_H_
#pragma once
#define CUTOFFDIST			1.f
#define STIFFNESS			0.005f
#define RESTDENSITY			0
#define SCALE               16.f
#define GRAVITY             -0.0001f
//#define GRAVITY             0
#define RESTRHO				1.7f
#define VISALPHA			0.005f

#include <stdio.h>
#include <math.h>
#include "helper_math.h"
#include "math_constants.h"
#include "Parameters.cuh"

#if USE_TEX
#define FETCH(t, i) tex1Dfetch(t##Tex, i)
#else
#define FETCH(t, i) t[i]
#endif


__constant__ SimParams params;


struct integrate_functor
{
	float deltaTime;

	__host__ __device__
		integrate_functor(float delta_time) : deltaTime(delta_time) {}

	template <typename Tuple>
	__device__
		void operator()(Tuple t)
	{
		volatile float4 posData = thrust::get<0>(t);
		volatile float4 velData = thrust::get<1>(t);
		float3 pos = make_float3(posData.x, posData.y, posData.z);
		float3 vel = make_float3(velData.x, velData.y, velData.z);

		int size = params.gridSize/2;
		vel += params.gravity * deltaTime;
		vel *= params.globalDamping;

		// new position = old position + velocity * deltaTime
		pos += vel * deltaTime;

		// set this to zero to disable collisions with cube sides
#if 1

		if (pos.x > size - params.radius)
		{
			pos.x = size - params.radius;
			vel.x *= params.boundaryDamping;
		}

		if (pos.x < -size + params.radius)
		{
			pos.x = -size + params.radius;
			vel.x *= params.boundaryDamping;
		}

		if (pos.y > size - params.radius)
		{
			pos.y = size - params.radius;
			vel.y *= params.boundaryDamping;
		}

		if (pos.z > size - params.radius)
		{
			pos.z = size - params.radius;
			vel.z *= params.boundaryDamping;
		}

		if (pos.z < -size + params.radius)
		{
			pos.z = -size + params.radius;
			vel.z *= params.boundaryDamping;
		}

#endif

		if (pos.y < -size + params.radius)
		{
			pos.y = -size + params.radius;
			vel.y *= params.boundaryDamping;
		}

		// store new position and velocity
		thrust::get<0>(t) = make_float4(pos, posData.w);
		thrust::get<1>(t) = make_float4(vel, velData.w);
	}
};

// calculate position in uniform grid
__device__ int3 calcGridPos(float3 p)
{
	int3 gridPos;
	gridPos.x = floor((p.x - params.worldPos.x) / params.cellSize);
	gridPos.y = floor((p.y - params.worldPos.y) / params.cellSize);
	gridPos.z = floor((p.z - params.worldPos.z) / params.cellSize);
	return gridPos;
}

// calculate address in grid from position (clamping to edges)
__device__ uint calcGridHash(int3 gridPos)
{
	gridPos.x = gridPos.x & (params.cellNum - 1);  // wrap grid, assumes size is power of 2
	gridPos.y = gridPos.y & (params.cellNum - 1);
	gridPos.z = gridPos.z & (params.cellNum - 1);
	return __umul24(__umul24(gridPos.z, params.cellNum), params.cellNum) + __umul24(gridPos.y, params.cellNum) + gridPos.x;
}

// calculate grid hash value for each particle
__global__
void calcHashD(uint   *gridParticleHash,  // output
uint   *gridParticleIndex, // output
float4 *pos,               // input: positions
uint    numParticles)
{
	uint index = __umul24(blockIdx.x, blockDim.x) + threadIdx.x;

	if (index >= numParticles) return;

	volatile float4 p = pos[index];

	// get address in grid
	int3 gridPos = calcGridPos(make_float3(p.x, p.y, p.z));
	uint hash = calcGridHash(gridPos);

	// store grid hash and particle index
	gridParticleHash[index] = hash;
	gridParticleIndex[index] = index;
}

// rearrange particle data into sorted order, and find the start of each cell
// in the sorted hash array
__global__
void reorderDataAndFindCellStartD(uint   *cellStart,        // output: cell start index
uint   *cellEnd,          // output: cell end index
float4 *sortedPos,        // output: sorted positions
float4 *sortedVel,        // output: sorted velocities
uint   *gridParticleHash, // input: sorted grid hashes
uint   *gridParticleIndex,// input: sorted particle indices
float4 *oldPos,           // input: sorted position array
float4 *oldVel,           // input: sorted velocity array
uint    numParticles)
{
	extern __shared__ uint sharedHash[];    // blockSize + 1 elements
	uint index = __umul24(blockIdx.x, blockDim.x) + threadIdx.x;

	uint hash;

	// handle case when no. of particles not multiple of block size
	if (index < numParticles)
	{
		hash = gridParticleHash[index];

		// Load hash data into shared memory so that we can look
		// at neighboring particle's hash value without loading
		// two hash values per thread
		sharedHash[threadIdx.x + 1] = hash;

		if (index > 0 && threadIdx.x == 0)
		{
			// first thread in block must load neighbor particle hash
			sharedHash[0] = gridParticleHash[index - 1];
		}
	}

	__syncthreads();

	if (index < numParticles)
	{
		// If this particle has a different cell index to the previous
		// particle then it must be the first particle in the cell,
		// so store the index of this particle in the cell.
		// As it isn't the first particle, it must also be the cell end of
		// the previous particle's cell

		if (index == 0 || hash != sharedHash[threadIdx.x])
		{
			cellStart[hash] = index;

			if (index > 0)
				cellEnd[sharedHash[threadIdx.x]] = index;
		}

		if (index == numParticles - 1)
		{
			cellEnd[hash] = index + 1;
		}

		// Now use the sorted index to reorder the pos and vel data
		uint sortedIndex = gridParticleIndex[index];
		float4 pos = FETCH(oldPos, sortedIndex);       // macro does either global read or texture fetch
		float4 vel = FETCH(oldVel, sortedIndex);       // see particles_kernel.cuh

		sortedPos[index] = pos;
		sortedVel[index] = vel;
	}


}

// collide two spheres using DEM method
__device__
float3 collideSpheres(float3 posA, float3 posB,
float3 velA, float3 velB,
float radiusA, float radiusB,
float attraction)
{
	// calculate relative position
	float3 relPos = posB - posA;

	float dist = length(relPos);
	float collideDist = radiusA + radiusB;

	float3 force = make_float3(0.0f);

	if (dist < collideDist)
	{
		float3 norm = relPos / dist;

		// relative velocity
		float3 relVel = velB - velA;

		// relative tangential velocity
		float3 tanVel = relVel - (dot(relVel, norm) * norm);

		// spring force
		force = -params.spring*(collideDist - dist) * norm;
		// dashpot (damping) force
		force += params.damping*relVel;
		// tangential shear force
		force += params.shear*tanVel;
		// attraction
		force += attraction*relPos;
	}

	return force;
}


__device__
float calcDensityD(int3    gridPos,
uint    index,
float4  pos,
float4  vel,
float4 *oldPos,
float4 *oldVel,
uint   *cellStart,
uint   *cellEnd)
{
	uint gridHash = calcGridHash(gridPos);

	uint startIndex = FETCH(cellStart, gridHash);

	float w = 0;

	if (startIndex != 0xffffffff)
	{
		uint endIndex = FETCH(cellEnd, gridHash);

		for (uint j = startIndex; j < endIndex; j++)
		{

			float3 pos1 = make_float3(pos);
			float3 pos2 = make_float3(FETCH(oldPos, j));
			float3 vel2 = make_float3(FETCH(oldVel, j));

			float dist = length(pos1 - pos2) * SCALE;

			float h = CUTOFFDIST;
			if (dist >= 0 && dist <= h)
			{
				w += 315.f / (64.f * CUDART_PI_F * pow(h, 9)) * pow(h*h - dist*dist, 3);
			}
		}
	}

	return w;
}

__device__
float3 calcForceD(int3    gridPos,
uint    index,
float4  pos,
float4  vel,
float4 *oldPos,
float4 *oldVel,
uint   *cellStart,
uint   *cellEnd)
{
	uint gridHash = calcGridHash(gridPos);

	uint startIndex = FETCH(cellStart, gridHash);

	float3 force = make_float3(0.0f);

	if (startIndex != 0xffffffff)
	{
		uint endIndex = FETCH(cellEnd, gridHash);

		for (uint j = startIndex; j < endIndex; j++)
		{
			if (j != index)
			{
				float3 pos1 = make_float3(pos);
				float3 vel1 = make_float3(vel);
				float3 pos2 = make_float3(FETCH(oldPos, j));
				float3 vel2 = make_float3(FETCH(oldVel, j));

				float3 relPos = pos1 - pos2;
				float dist = length(relPos);
				float3 normal = relPos / dist;
				dist = dist * SCALE;

				float h = CUTOFFDIST;
				if (dist >= 0 && dist <= h)
				{
					float l = h*h - dist*dist;
					float grad = -dist * 945.f / (32.f*CUDART_PI_F*pow(h, 9)) * l*l;
					float lapl = 945.f / (8.f * CUDART_PI_F*pow(h, 9)) * l * (dist*dist - 3.f / 4.f * l);

					float p1 = STIFFNESS * (vel.w - RESTRHO);
					float rho = FETCH(oldVel, j).w;
					float p2 = STIFFNESS * (rho - RESTRHO);

					float press = -0.5f * (p1 + p2) * grad / rho;
					float3 visco = (vel2 - vel1) * lapl / rho * VISALPHA;
					force = force + press * normal + visco;
					//force = force + press * normal;
				}
			}
		}
	}
	return force;
}


__global__
void calcDensity(float4 *oldPos,               // input: sorted positions
float4 *oldVel,               // input: sorted velocities
uint   *gridParticleIndex,    // input: sorted particle indices
uint   *cellStart,
uint   *cellEnd,
uint    numParticles)
{
	uint index = __mul24(blockIdx.x, blockDim.x) + threadIdx.x;

	if (index >= numParticles) return;

	// read particle data from sorted arrays
	float4 pos = FETCH(oldPos, index);
	float4 vel = FETCH(oldVel, index);

	// get address in grid
	int3 gridPos = calcGridPos(make_float3(pos));

	// examine neighbouring cells
	float3 force = make_float3(0.0f);
	float density = 0;

	for (int z = -1; z <= 1; z++)
	{
		for (int y = -1; y <= 1; y++)
		{
			for (int x = -1; x <= 1; x++)
			{
				int3 neighbourPos = gridPos + make_int3(x, y, z);
				density += calcDensityD(neighbourPos, index, pos, vel, oldPos, oldVel, cellStart, cellEnd);
			}
		}
	}

	oldVel[index].w = density;
}

__global__
void calcForce(float4 *newVel, //output: new velocity
float4 *oldPos,               // input: sorted positions
float4 *oldVel,               // input: sorted velocities
uint   *gridParticleIndex,    // input: sorted particle indices
uint   *cellStart,
uint   *cellEnd,
uint    numParticles)
{
	uint index = __mul24(blockIdx.x, blockDim.x) + threadIdx.x;

	if (index >= numParticles) return;

	// read particle data from sorted arrays
	float4 pos = FETCH(oldPos, index);
	float4 vel = FETCH(oldVel, index);

	// get address in grid
	int3 gridPos = calcGridPos(make_float3(pos));

	// examine neighbouring cells
	float3 force = make_float3(0.0f);

	for (int z = -1; z <= 1; z++)
	{
		for (int y = -1; y <= 1; y++)
		{
			for (int x = -1; x <= 1; x++)
			{
				int3 neighbourPos = gridPos + make_int3(x, y, z);
				force += calcForceD(neighbourPos, index, pos, vel, oldPos, oldVel, cellStart, cellEnd);
			}
		}
	}

	float rho = vel.w;
	float3 pos1 = make_float3(pos);
	float3 vel1 = make_float3(vel);

	force = make_float3(0, GRAVITY, 0) + force / rho;
	//force = force / rho;
	// collide with cursor sphere
	//force += collideSpheres(pos1, params.colliderPos, vel1, make_float3(0.0f, 0.0f, 0.0f), params.radius, params.colliderRadius, 0.0f);

	// write new velocity back to original unsorted location
	uint originalIndex = gridParticleIndex[index];
	newVel[originalIndex] = make_float4(vel1 + force, 0.0f);
}

#endif
