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
	static const int MAX_NUM = 121;    //0~1�̒l����ׂ邩��11*11��
	static const int COLUMN_NUM = 11;  //1��ɉ����ׂ邩
	static iexMesh* m_model;
	static Object* m_obj[MAX_NUM];
};