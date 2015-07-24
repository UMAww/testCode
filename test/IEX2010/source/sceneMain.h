//*****************************************************************************************************************************
//
//		メインシーン
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

	static const int CUBE_SIZE = 128;
	static const int MIPMAP_NUM;
public:
	~sceneMain();
	//	初期化
	bool Initialize();
	//	更新・描画
	void Update();	//	更新
	void Render();	//	描画

	void DynamicCreateCubeMap();	//動的キューブマップ作成
	void StaticCreateCubeMap( char* filename );
};


