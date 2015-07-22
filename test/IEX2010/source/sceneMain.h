//*****************************************************************************************************************************
//
//		���C���V�[��
//
//*****************************************************************************************************************************

#include	"Camera.h"
#include	"Object.h"

class	sceneMain : public Scene
{
private:
	iexView*	view;
	iexMesh* stage;
	iexMesh* sky;
	Camera* camera;
	Object* sphere;

	bool Renderflg;

	iex2DObj *normal;
	static const int CUBE_SIZE = 256;
public:
	~sceneMain();
	//	������
	bool Initialize();
	//	�X�V�E�`��
	void Update();	//	�X�V
	void Render();	//	�`��

	void DynamicCreateCubeMap();	//���I�L���[�u�}�b�v�쐬
	void StaticCreateCubeMap( char* filename );
};


