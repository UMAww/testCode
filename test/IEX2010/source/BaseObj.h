#ifndef __BASEOBJ_H__
#define __BASEOBJ_H__

class BaseObj
{
public:
	BaseObj():m_pos( .0f, .0f, .0f ), m_angle( .0f, .0f, .0f ), m_scale( 1.0f, 1.0f, 1.0f ){}
	virtual ~BaseObj()=0{};
	virtual void Init(){}
	virtual void Update()=0{}
	virtual void Render()=0{}
	virtual void Render( iexShader* shader, char* name )=0{}

	void SetPos( Vector3 pos ){ this->m_pos = pos; }
	void SetAngle( Vector3 angle ){ this->m_angle = angle; }
	void SetScale( float scale ){ this->m_scale.x = this->m_scale.y = this->m_scale.z = scale; }
	void SetScale( Vector3 scale ){ this->m_scale = scale; }

	Vector3 GetPos(){ return this->m_pos; }
	Vector3 GetAngle(){ return this->m_angle; }
	Vector3 GetScale(){ return this->m_scale; }
protected:
	Vector3 m_pos;
	Vector3 m_angle;
	Vector3 m_scale;
	Vector3 m_move;
	float   m_vec;
};

#endif