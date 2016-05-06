#ifndef __OBJECT_H__
#define __OBJECT_H__

#include	"BaseObj.h"
#include    "ObjectManager.h"

class Object	:	public BaseObj
{
public:
	Object();
	Object( iexMesh* obj );
	Object( char* filename );
	Object( char* filename, Vector3 pos, Vector3 angle, Vector3 scale );
	~Object();

	void Init( char* filname );
	void Update();
	void Render();
	void Render(iexShader* shader, char* name );

	//アクセサ
	float GetRoughness(){ return this->m_roughness; }
	float GetMetalness(){ return this->m_metalness; }
	void SetRoughness(float value){ this->m_roughness = value; }
	void SetMetalness(float value){ this->m_metalness = value; }
private:
	iexMesh* m_obj;
	Vector3 m_move;
	float m_vec;

	float m_metalness;
	float m_roughness;

	static const float SPEED;
	//マネージャーで一括管理
	friend class ObjectManager;
	bool m_isEnable;
private:
	void Move();
};
#endif