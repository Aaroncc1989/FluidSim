#pragma once
#include "Mesh.h"
class TreeMesh :public Mesh
{
public:
	TreeMesh(void);
	~TreeMesh(void);

	static TreeMesh* TreeMesh::GenerateCylinder();
	static TreeMesh* TreeMesh::GenerateLeaf();
	static TreeMesh* TreeMesh::GenerateGrass();
	static TreeMesh* TreeMesh::GenerateQuad();
	static TreeMesh* TreeMesh::GenerateTriangle();
	static TreeMesh* TreeMesh::GenerateCircle();
	static TreeMesh* TreeMesh::GenerateFlower();
	static TreeMesh* TreeMesh::GenerateWater();
	float rtop;
	float rbot;
	float height;
	float rcircle;
	static float treememory;
};
