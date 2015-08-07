#ifndef __CAMERA_H__
#define __CAMERA_H__

class Camera
{
private:

	iexView* view;
	Vector3 pos;
	Vector3 angle;
	Vector3 target;

	Matrix playerMat;
	float DIST;

	D3DXQUATERNION targetQ;
	D3DXQUATERNION currentQ;

	Vector3 lPos;

	void Rotate();

	//static const float DIST;
	static const float SPEED;
	static const float UPLIMIT;
	static const float DOWNLIMIT;

public:

	Camera();
	Camera( Vector3 pos, Vector3 target );
	~Camera();

	void Update( const Vector3& pos );
	void Clear( long color = 0x000000 );
	void ClearScreen( long color = 0x00000000 );

	void Set( const Vector3& pos, const Vector3& target );
	void SetDist( float d ){ this->DIST = d; }

	Vector3 GetPos(){ return this->pos; }
	Vector3 GetTarget(){ return this->target; }

};

#endif