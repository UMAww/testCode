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

	bool Renderflg;

	//G-Buffer�pRenderTarget
	Surface* back;
	iex2DObj* screen;
	iex2DObj* color;
	iex2DObj* normal;
	iex2DObj* Depth;
	iex2DObj* MR;	//M:Metalness, R:Roughness

	static const int CUBE_SIZE = 512;
	static const int MIPMAP_NUM;
	static const int PLIGHT_NUM = 10;

	Vector3 pLight_Pos[PLIGHT_NUM];
	Vector3 pLight_Color[PLIGHT_NUM];
	float pLight_Range[PLIGHT_NUM];
	int light_index;

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

	void CreateG_Buffer();

	void AddPoint_Light( const Vector3& pos, const Vector3& color, float range );
	void DelPoint_Light();
};


