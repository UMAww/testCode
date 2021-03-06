#pragma once

#include"Object.h"

class Object;

class ObjectManager
{
public:
	ObjectManager(char *filename);
	~ObjectManager();

	void Update();
	void Render();
	void Render(char* pass);
private:
	static const int MAX_NUM = 121;    //0~1の値を並べるから11*11個
	static const int COLUMN_NUM = 11;  //1列に何個並べるか
	static iexMesh* m_model;
	static Object* m_obj[MAX_NUM];
};