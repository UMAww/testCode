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
	Camera* camera;
	Object* sphere;

	bool Renderflg;
public:
	~sceneMain();
	//	������
	bool Initialize();
	//	�X�V�E�`��
	void Update();	//	�X�V
	void Render();	//	�`��
};


