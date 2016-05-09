//*****************************************************************************************************************************
//
//		���C���V�[��
//
//*****************************************************************************************************************************

#include	"Camera.h"
#include	"Object.h"
#include	"Character.h"

#define DeleteObj(p){ if( p != nullptr ){ delete p; p = nullptr; }}

class	sceneMain : public Scene
{
private:
	iexMesh* stage;
	iexMesh* sky;
	Camera* camera;
	ObjectManager* sphere;

	bool Renderflg;

	//���C�e�B���O���ʏo�͗p�o�b�t�@
	Surface*  back;
	iex2DObj* screen;
	iex2DObj* IBL;

	//G-Buffer�pRenderTarget
	iex2DObj* color;    //BaseColor�o��
	iex2DObj* normal;   //�@���o��
	iex2DObj* depth;    //�[�x���o��
	iex2DObj* MR;	    //M:Metalness, R:Roughness
	iex2DObj* light;    //���C�g�}�b�v
	iex2DObj* specular; //�X�y�L����IBL�o��
#ifdef _DEBUG
	bool      show_buffer; //G-Buffer�������_�����O���邩
#endif

	static const int CUBE_SIZE = 512;
	static const int MIPMAP_NUM;

	//Post-Effect
	iex2DObj* SSAO;
	bool useSSAO;
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
private:
	void ForwardRenderProc();
	void DeferredRenderProc();
	void CreateG_Buffer();
#ifdef _DEBUG
	void ShowG_Buffer();
#endif
	void CreateSSAO();
	void PostEffectProc();
	void DirLight( Vector3 light_vec, Vector3 light_color );
};


