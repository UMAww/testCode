//*****************************************************************************************************************************
//
//		���C���V�[��
//
//*****************************************************************************************************************************

#include	"Camera.h"
#include	"Object.h"
#include	"Character.h"

class	sceneMain : public Scene
{
private:
	iexView*	view;
	iexMesh* stage;
	iexMesh* sky;
	Camera* camera;
	Object* box,*sphere;
	Character* p;

	bool Renderflg;

	static const int CUBE_SIZE = 512;
	static const int MIPMAP_NUM;
public:
	~sceneMain();
	//	������
	bool Initialize();
	//	�X�V�E�`��
	void Update();	//	�X�V
	void Render();	//	�`��

	//�L���[�u�}�b�v�쐬
	//BasePoint:�B�e���_
	void CreateCubeMap( Vector3 BasePoint = Vector3( .0f, 2.0f, .0f));
	void StaticCreateCubeMap( char* filename );
};


