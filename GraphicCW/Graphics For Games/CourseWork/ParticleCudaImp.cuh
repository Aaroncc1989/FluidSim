#ifndef _PARTICLES_KERNEL_H_
#define _PARTICLES_KERNEL_H_
#pragma once
#include <stdio.h>
#include <math.h>
#include "helper_math.h"
#include "math_constants.h"
#include "Parameters.cuh"

#define FETCH(t, i) t[i]

__constant__ SimParams params;


struct integrate_functor
{
	float deltaTime;

	__host__ __device__
		integrate_functor(float delta_time) : deltaTime(delta_time){}

	template <typename Tuple>
	__device__
		void operator()(Tuple t)
	{
		volatile float4 posData = thrust::get<0>(t);
		volatile float4 velData = thrust::get<1>(t);
		float3 pos = make_float3(posData.x, posData.y, posData.z);
		float3 vel = make_float3(velData.x, velData.y, velData.z);

		uint3 size = params.gridSize;
		//vel += params.gravity * deltaTime;
		vel *= params.globalDamping;
		// new position = old position + velocity * deltaTime
		pos += vel * deltaTime;
		// set this to zero to disable collisions with cube sides
#if 1

		if (pos.x > size.x - params.radius)
		{
			pos.x = size.x - params.radius;
			vel.x *= params.boundaryDamping;
		}

		if (pos.x <  params.radius)
		{
			pos.x =  params.radius;
			vel.x *= params.boundaryDamping;
		}

		if (pos.y > size.y  - params.radius)
		{
			pos.y = size.y  - params.radius;
			vel.y *= params.boundaryDamping;
		}

		if (pos.z > size.z - params.radius)
		{
			pos.z = size.z - params.radius;
			vel.z *= params.boundaryDamping;
		}

		if (pos.z < params.radius)
		{
			pos.z = params.radius;
			vel.z *= params.boundaryDamping;
		}

#endif

		if (pos.y <  params.radius)
		{
			pos.y =  params.radius;
			vel.y *= params.boundaryDamping;
		}

		// store new position and velocity
		thrust::get<0>(t) = make_float4(pos, velData.w);
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
	gridPos.x = gridPos.x & (params.cellNum.x - 1);  // wrap grid, assumes size is power of 2
	gridPos.y = gridPos.y & (params.cellNum.y - 1);
	gridPos.z = gridPos.z & (params.cellNum.z - 1);
	return __umul24(__umul24(gridPos.z, params.cellNum.y), params.cellNum.x) + __umul24(gridPos.y, params.cellNum.x) + gridPos.x;
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
float calcDensityD(int3    gridPos,
uint    index,
float4  &pos,
float4 *oldPos,
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

			float dist = length(pos1 - pos2) * params.scale;

			float h = params.cutoffdist;
			if (dist >= 0 && dist < h)
			{
				w += 315.f / (64.f * CUDART_PI_F * pow(h, 9)) * pow(h*h - dist*dist, 3);			//calculate density
				pos.w ++;																		//count the num of neighbor
			}
		}
	}

	return w;
}

__global__
void calcDensity(float4 *oldPos,               // input: sorted positions
float4 *oldVel,								   // input: sorted vel
uint   *gridParticleIndex,					   // input: sorted particle indices
uint   *cellStart,
uint   *cellEnd,
uint    numParticles)
{
	uint index = __mul24(blockIdx.x, blockDim.x) + threadIdx.x;

	if (index >= numParticles) return;

	// read particle data from sorted arrays
	float4 pos = FETCH(oldPos, index);
	float4 vel = FETCH(oldVel, index);

	pos.w = 0;
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
				density += calcDensityD(neighbourPos, index, pos, oldPos, cellStart, cellEnd);
			}
		}
	}
	oldPos[index].w = pos.w;
	oldVel[index].w = density;
}

__device__
float3 calcForceD(int3    gridPos,
uint    index,
float4  pos,
float4  vel,
float4 *oldPos,
float4 *oldVel,
uint   *cellStart,
uint   *cellEnd
)
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
				dist = dist * params.scale;

				float h = params.cutoffdist;
				if (dist >= 0 && dist < h)
				{
					float l = h*h - dist*dist;
					float grad = -dist * 945.f / (32.f*CUDART_PI_F*pow(h, 9)) * l*l;						//gradient of kernel
					float lapla = 945.f / (8.f * CUDART_PI_F*pow(h, 9)) * l * (dist*dist - 3.f / 4.f * l);	//laplacian of kernel

					float p1 = params.stiffness * (vel.w - params.restRHO);							// pressure at i 
					float rho2 = FETCH(oldVel, j).w;													//density at j
					float p2 = params.stiffness * (rho2 - params.restRHO);							//pressure at j
							
					float press = -(p1 + p2) * grad / (rho2*2.0f);									//force of pressure
					float3 relVel = vel2 - vel1;
					float3 tanVel = relVel - (dot(relVel, normal) * normal);
					float3 visco = relVel*lapla / rho2 * params.visalocityScale;			//viscosity of pressure
					float3 foamForce = params.shear * tanVel;

					force = force + press * normal + visco + foamForce;											//final force
				}
			}
		}
	}
	return force;
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
	float count = pos.w;
	float3 pos1 = make_float3(pos);
	float3 vel1 = make_float3(vel);

	force = params.gravity + force / rho;
	// collide with cursor sphere
	//force += collideSpheres(pos1, *solidPos, vel1, make_float3(0.0f, 0.0f, 0.0f), params.radius, params.colliderRadius, 0.0f);
	// write new velocity back to original unsorted location
	uint originalIndex = gridParticleIndex[index];
	newVel[originalIndex] = make_float4(vel1 + force, count);
}


__device__
float3 collideSpheres(float3 posA, float3 posB,
float3 velA, float3 velB,
float3 &angVel)
{
	float solidRadius = 10.0f;
	// calculate relative position
	float3 relPos = posB - posA;

	float dist = length(relPos);
	float collideDist = params.radius + solidRadius;

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

		angVel = cross(norm, tanVel);
		// dashpot (damping) force
		//force += params.damping*relVel;
		// tangential shear force
		//force += params.shear*tanVel;
		// attraction
		//force += params.attraction*relPos;
	}

	return force;
}


__global__ void interAct(float4* newVel,
	float4* oldPos,
	float4* oldVel, 
	uint   *gridParticleIndex,
	uint numParticles, float4 *solidPos, float4 *solidVel, float4 *buoyancy, float4 *buoyancyAng)
{
	uint index = __mul24(blockIdx.x, blockDim.x) + threadIdx.x;

	if (index >= numParticles) return;

	float3 pos = make_float3(FETCH(oldPos, index));
	float3 vel = make_float3(FETCH(oldVel, index));
	float count = FETCH(oldVel, index).w;

	int3 gridPos = calcGridPos(pos);
	float3 force = make_float3(0.0f);

	float3 angVel = make_float3(0.0f);
	force += collideSpheres(pos, make_float3(*solidPos), vel, make_float3(*solidVel), angVel);

	uint originalIndex = gridParticleIndex[index];
	buoyancy[originalIndex] = make_float4(-force, 0);
	buoyancyAng[originalIndex] = make_float4(angVel, 0);
	newVel[originalIndex] = newVel[originalIndex] + make_float4(force, 0);
}

#endif
