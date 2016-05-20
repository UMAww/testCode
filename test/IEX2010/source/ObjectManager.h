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
	static const int MAX_NUM = 121;    //0~1‚Ì’l‚ð•À‚×‚é‚©‚ç11*11ŒÂ
	static const int COLUMN_NUM = 11;  //1—ñ‚É‰½ŒÂ•À‚×‚é‚©
	static iexMesh* m_model;
	static Object* m_obj[MAX_NUM];
};