#ifndef __OBJECT_H__
#define __OBJECT_H__

#include	"BaseObj.h"

class Object	:	public BaseObj
{
public:

	Object();
	Object( char* filename );
	Object( char* filename, Vector3 pos, Vector3 angle, Vector3 scale );
	~Object();

	void Init( char* filname );
	void Update();
	void Render();
	void Render( char* name );

private:

	iexMesh* obj;
	Vector3 move;
	float vec;

	float metalness;
	float roughness;

	static const float SPEED;
	void Move();
};
#endif