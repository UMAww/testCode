#ifndef __BASEOBJ_H__
#define __BASEOBJ_H__

class BaseObj
{
protected:
	Vector3 pos;
	Vector3 angle;
	Vector3 scale;
	Vector3 move;
	float vec;
public:
	BaseObj():pos( .0f, .0f, .0f ), angle( .0f, .0f, .0f ), scale( 1.0f, 1.0f, 1.0f ){}
	virtual ~BaseObj()=0{};
	virtual void Init(){}
	virtual void Update()=0{}
	virtual void Render()=0{}
	virtual void Render( char* name )=0{}

	void SetPos( Vector3 pos ){ this->pos = pos; }
	void SetAngle( Vector3 angle ){ this->angle = angle; }
	void SetScale( float scale ){ this->scale.x = this->scale.y = this->scale.z = scale; }
	void SetScale( Vector3 scale ){ this->scale = scale; }

	Vector3 GetPos(){ return this->pos; }
	Vector3 GetAngle(){ return this->angle; }
	Vector3 GetScale(){ return this->scale; }
};

#endif