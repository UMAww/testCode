#ifndef __CHARACTER_H__
#define __CHARACTER_H__

#include	"BaseObj.h"
#include	"Model.h"

enum class PlayerState
{
	MOVE = 0,
	ATTACK,
};

class Character	:	public BaseObj
{
private:

	Model* obj;
	PlayerState state;

	static const float SPEED;
	void ChangeMotion( int motion, float blendspeed );
	void Move();

public:

	Character();
	Character( char* filename, float speed = 1.0f );
	~Character();

	void Init( char* filename, float speed );
	void Update();
	void Render();
	void Render( char* name );

	void SetMotion( int n, float blendspeed ){ ChangeMotion( n, blendspeed ); }
	Matrix GetMatrix(){ return this->obj->TransMatrix; }

};

#endif