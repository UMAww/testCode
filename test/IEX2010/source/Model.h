#ifndef __MODEL_H__
#define __MODEL_H__

//モーション補間してくれるiex3DObj
//モーションの再生速度も変えられるように
class Model : public iex3DObj
{
public:

	Model( char* filename, float speed = 1.0f );
	~Model();

	Model* Clone();

	void Animation();

	void UpdateSkinMeshFrame();
	void Update();

	void SetMotionSpeed( float speed ){ this->motionSpeed = speed; }
	void SetMotion( const int nextMotion, float blendSpeed = 0.05f );
private:
	unsigned int interpolationMotionNo;
	unsigned int interpolationMotionFrame;
	float interpolationRate;
	float interpolationSpeed;

	float motionSpeed;
	float fFrame;
};

#endif