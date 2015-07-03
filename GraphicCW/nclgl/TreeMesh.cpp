#include "TreeMesh.h"


TreeMesh::TreeMesh(void) :Mesh()
{
	rtop = 0.02f;
	rbot = 0.1f;
	height = 5.0f;
	rcircle = 0.15f;
}


TreeMesh::~TreeMesh(void)
{
	treememory -= 4 * 5 * 3 * this->numVertices;
}

TreeMesh* TreeMesh::GenerateCylinder()
{
	TreeMesh* m = new TreeMesh();
	m->type = GL_TRIANGLE_STRIP;
	m->numVertices = 122;

	m->indices = NULL;

	m->vertices = new Vector3[m->numVertices];
	m->textureCoords = new Vector2[m->numVertices];
	m->colours = new Vector4[m->numVertices];

	for (int i = 0; i < 61; i++)
	{

		float x = cos(2.0f * PI / 60.0f * i)*(m->rbot);
		float y = sin(2.0f * PI / 60.0f * i)*(m->rbot);

		m->vertices[i * 2] = Vector3(x, y, 0.0f);
		m->textureCoords[i * 2] = Vector2(1.0 / 60.0*i, 0.0f);
		m->colours[i * 2] = Vector4(1.0f, 1.0f, 1.0f, 1.0f);
	}

	for (int i = 0; i < 61; i++)
	{
		float x = cos(2.0f*PI / 60.0f*i)*(m->rtop);
		float y = sin(2.0f * PI / 60.0f * i)*(m->rtop);

		m->vertices[i * 2 + 1] = Vector3(x, y, m->height);
		m->textureCoords[i * 2 + 1] = Vector2(1.0 / 60.0*i, m->height);
		m->colours[i * 2 + 1] = Vector4(1.0f, 1.0f, 1.0f, 1.0f);
	}

	m->numIndices = (m->numVertices - 2) * 3;
	m->indices = new unsigned int[m->numIndices];
	int offset = 0;
	for (int i = 2; i < m->numVertices; i++)
	{
		if (i % 2 == 0)
		{
			m->indices[offset++] = i - 1;
			m->indices[offset++] = i - 2;
			m->indices[offset++] = i;
		}
		else
		{
			m->indices[offset++] = i - 2;
			m->indices[offset++] = i - 1;
			m->indices[offset++] = i;
		}
	}

	m->GenerateNormals();
	m->GenerateTangents();

	m->BufferData();

	treememory += 4 * 5 * 3 * m->numVertices;
	return m;
}

TreeMesh* TreeMesh::GenerateLeaf()
{
	TreeMesh* m = new TreeMesh();
	m->type = GL_TRIANGLES;
	m->numVertices = 18;

	m->vertices = new Vector3[m->numVertices];
	m->textureCoords = new Vector2[m->numVertices];
	m->colours = new Vector4[m->numVertices];
	m->normals = new Vector3[m->numVertices];


	m->vertices[0] = Vector3(0, 0, 0);
	m->vertices[1] = Vector3(0, 0.1f, 0);
	m->vertices[2] = Vector3(0.3f, 0.2f, 0);
	m->vertices[3] = Vector3(0, 0, 0);
	m->vertices[4] = Vector3(0, 0.3f, 0);
	m->vertices[5] = Vector3(0.5f, 0.4f, 0.01f);
	m->vertices[6] = Vector3(0, 0, 0.01f);
	m->vertices[7] = Vector3(0.5f, 0.4f, 0.01f);
	m->vertices[8] = Vector3(0, 0.3f, 0.01f);
	m->vertices[9] = Vector3(0, 0, 0.01f);
	m->vertices[10] = Vector3(0, 0.3f, 0.01f);
	m->vertices[11] = Vector3(-0.5f, 0.4f, 0.01f);
	m->vertices[12] = Vector3(0, 0.3f, -0.01f);
	m->vertices[13] = Vector3(0.2f, 0.1f, -0.01f);
	m->vertices[14] = Vector3(0, 0.8f, -0.01f);
	m->vertices[15] = Vector3(0, 0.3f, -0.01f);
	m->vertices[16] = Vector3(0, 0.8f, -0.01f);
	m->vertices[17] = Vector3(-0.2f, 0.1f, -0.01f);

	m->normals[0] = Vector3(0, -1.f, 1.f);
	m->normals[1] = Vector3(0, 1.f, 1.f);
	m->normals[2] = Vector3(0.5f, 0.5f, 1.f);
	m->normals[3] = Vector3(0, 0, 1.f);
	m->normals[4] = Vector3(0, 1.f, 1.f);
	m->normals[5] = Vector3(0.5f, 0.5f, 1.f);
	m->normals[6] = Vector3(0, -1.f, 1.f);
	m->normals[7] = Vector3(0, 1.f, 1.f);
	m->normals[8] = Vector3(0.5f, 0.5f, 1.f);
	m->normals[9] = Vector3(0, 0, 1.f);
	m->normals[10] = Vector3(0, 1.f, 1.f);
	m->normals[11] = Vector3(0.5f, 0.5f, 1.f);
	m->normals[12] = Vector3(0, -1.f, 1.f);
	m->normals[13] = Vector3(0, 1.f, 1.f);
	m->normals[14] = Vector3(0.5f, 0.5f, 1.f);
	m->normals[15] = Vector3(0, 0, 1.f);
	m->normals[16] = Vector3(0, 1.f, 1.f);
	m->normals[17] = Vector3(0.5f, 0.5f, 1.f);

	for (int i = 0; i < m->numVertices; i++)
	{
		m->textureCoords[i].x = m->vertices[i].x * m->vertices[i].x;
		m->textureCoords[i].y = m->vertices[i].y * m->vertices[i].y;
		m->colours[i] = Vector4(1.0f, 0, 0, 1.0f);
		m->normals[i].Normalise();
	}
	m->GenerateTangents();
	m->BufferData();
	treememory += 4 * 5 * 3 * m->numVertices;
	return m;
}

TreeMesh* TreeMesh::GenerateGrass()
{
	TreeMesh* m = new TreeMesh();
	m->type = GL_TRIANGLES;
	m->numVertices = 3;

	m->vertices = new Vector3[m->numVertices];
	m->textureCoords = new Vector2[m->numVertices];
	m->colours = new Vector4[m->numVertices];
	m->normals = new Vector3[m->numVertices];

	m->vertices[0] = Vector3(-0.2f, 0, 0);
	m->vertices[2] = Vector3(0, 1.0f, 0);
	m->vertices[1] = Vector3(0.2f,0, 0);

	m->textureCoords[0] = Vector2(0, 0);
	m->textureCoords[2] = Vector2(0.5f, 0.5f);
	m->textureCoords[1] = Vector2(1.0f, 0);

	m->colours[0] = Vector4(1.0f,1.0f,1.0f,1.0f);
	m->colours[1] = Vector4(1.0f,1.0f,1.0f,1.0f);
	m->colours[2] = Vector4(1.0f, 1.0f, 1.0f, 1.0f);


	m->GenerateNormals();
	m->GenerateTangents();
	m->BufferData();
	treememory += 4 * 5 * 3 * m->numVertices;
	return m;
}

TreeMesh* TreeMesh::GenerateQuad()
{
	TreeMesh * m = new TreeMesh();

	m->numVertices = 6;
	m->type = GL_TRIANGLES;

	m->vertices = new Vector3[m->numVertices];
	m->textureCoords = new Vector2[m->numVertices];
	m->colours = new Vector4[m->numVertices];

	m->vertices[0] = Vector3(-1.0f, 1.0f, 0.0f);
	m->vertices[1] = Vector3(1.0f, 1.0f, 0.0f);
	m->vertices[2] = Vector3(1.0f, -1.0f, 0.0f);
	m->vertices[3] = Vector3(-1.0f, 1.0f, 0.0f);
	m->vertices[4] = Vector3(1.0f, -1.0f, 0.0f);
	m->vertices[5] = Vector3(-1.0f, -1.0f, 0.0f);

	m->textureCoords[0] = Vector2(-1.0f, 1.0f);
	m->textureCoords[1] = Vector2(1.0f, 1.0f);
	m->textureCoords[2] = Vector2(1.0f, -1.0f);
	m->textureCoords[3] = Vector2(-1.0f, 1.0f);
	m->textureCoords[4] = Vector2(1.0f, -1.0f);
	m->textureCoords[5] = Vector2(-1.0f, -1.0f);

	for (int i = 0; i < 6; ++i) {
		m->colours[i] = Vector4(1.0f, 1.0f, 1.0f, 1.0f);
	}

	m->GenerateNormals();
	m->GenerateTangents();
	m->BufferData();
	treememory += 4 * 5 * 3 * m->numVertices;
	return m;
}

TreeMesh* TreeMesh::GenerateCircle()
{
	TreeMesh * m = new TreeMesh();
	m->numVertices = 180;
	m->type = GL_TRIANGLES;

	m->vertices = new Vector3[m->numVertices];
	m->textureCoords = new Vector2[m->numVertices];
	m->colours = new Vector4[m->numVertices];
	m->normals = new Vector3[m->numVertices];

	for (int i = 0; i < 60; i++)
	{
		float x = cos(2.0f * PI / 60.0f * i)*(m->rcircle);
		float y = sin(2.0f * PI / 60.0f * i)*(m->rcircle);

		float x1 = cos(2.0f * PI / 60.0f * (i+1))*(m->rcircle);
		float y1 = sin(2.0f * PI / 60.0f * (i + 1))*(m->rcircle);

		m->vertices[i*3] = Vector3(0,0,-1.0f);
		m->textureCoords[i*3] = Vector2(0,0);
		m->vertices[i*3 + 1] = Vector3(x, y, 0);
		m->textureCoords[i+1] = Vector2(x, y);
		m->vertices[i*3 + 2] = Vector3(x1,y1,0);
		m->textureCoords[i*3+2] = Vector2(x1, y1);
	}

	for (int i = 0; i < 60; i++)
	{
		m->colours[i] = Vector4(1.f,1.f,1.f,1.f);
	}

	m->GenerateNormals();
	m->GenerateTangents();
	m->BufferData();
	treememory += 4 * 5 * 3 * m->numVertices;
	return m;
}

TreeMesh* TreeMesh::GenerateFlower()
{
	TreeMesh * m = new TreeMesh();
	m->numVertices = 180;
	m->type = GL_TRIANGLES;

	m->vertices = new Vector3[m->numVertices];
	m->textureCoords = new Vector2[m->numVertices];
	m->colours = new Vector4[m->numVertices];
	m->normals = new Vector3[m->numVertices];

	for (int i = 0; i < 60; i++)
	{
		float x = cos(2.0f * PI / 60.0f * i)*(m->rcircle);
		float y = sin(2.0f * PI / 60.0f * i)*(m->rcircle);

		float x1 = cos(2.0f * PI / 60.0f * (i + 1))*(m->rcircle);
		float y1 = sin(2.0f * PI / 60.0f * (i + 1))*(m->rcircle);

		m->vertices[i * 3] = Vector3(0, 0, -0.4f);
		m->textureCoords[i * 3] = Vector2(0, 0);
		m->vertices[i * 3 + 1] = Vector3(x, y, 0);
		m->textureCoords[i + 1] = Vector2(x, y);
		m->vertices[i * 3 + 2] = Vector3(x1, y1, 0);
		m->textureCoords[i * 3 + 2] = Vector2(x1, y1);
	}

	m->GenerateNormals();
	for (int i = 0; i < 180; i++)
	{
		m->colours[i] = Vector4(1.f, 1.f, 1.f, 1.f);
		m->normals[i] = m->normals[i] * (-1);
	}

	m->GenerateTangents();
	m->BufferData();
	treememory += 4 * 5 * 3 * m->numVertices;
	return m;
}

float TreeMesh::treememory = 0;

TreeMesh* TreeMesh::GenerateWater()
{
	TreeMesh * m = new TreeMesh();

	m->numVertices = 4;
	m->type = GL_TRIANGLE_STRIP;

	m->vertices = new Vector3[m->numVertices];
	m->textureCoords = new Vector2[m->numVertices];
	m->colours = new Vector4[m->numVertices];
	m->normals = new Vector3[m->numVertices];

	m->vertices[0] = Vector3(-1.0f, -1.0f, 0.0f);
	m->vertices[1] = Vector3(1.0f, -1.0f, 0.0f);
	m->vertices[2] = Vector3(-1.0f, 1.0f, 0.0f);
	m->vertices[3] = Vector3(1.0f, 1.0f, 0.0f);



	m->textureCoords[0] = Vector2(0, 0);
	m->textureCoords[1] = Vector2(1.0f, 0);
	m->textureCoords[2] = Vector2(1.0f, 1.0f);
	m->textureCoords[3] = Vector2(0, 1.0f);


	for (int i = 0; i < 4; ++i) {
		m->colours[i] = Vector4(1.0f, 1.0f, 1.0f, 1.0f);
	}

	m->numIndices = (m->numVertices - 2) * 3;
	m->indices = new unsigned int[m->numIndices];
	int offset = 0;
	for (int i = 2; i < m->numVertices; i++)
	{
		if (i % 2 == 0)
		{
			m->indices[offset++] = i - 1;
			m->indices[offset++] = i - 2;
			m->indices[offset++] = i;
		}
		else
		{
			m->indices[offset++] = i - 2;
			m->indices[offset++] = i - 1;
			m->indices[offset++] = i;
		}
	}

	m->GenerateNormals();
	m->GenerateTangents();
	m->BufferData();
	treememory += 4 * 5 * 3 * m->numVertices;
	return m;
}