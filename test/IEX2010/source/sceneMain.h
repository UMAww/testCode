//*****************************************************************************************************************************
//
//		メインシーン
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

	//ライティング結果出力用バッファ
	Surface*  back;
	iex2DObj* screen;
	iex2DObj* IBL;

	//G-Buffer用RenderTarget
	iex2DObj* color;    //BaseColor出力
	iex2DObj* normal;   //法線出力
	iex2DObj* depth;    //深度情報出力
	iex2DObj* MR;	    //M:Metalness, R:Roughness
	iex2DObj* light;    //ライトマップ
	iex2DObj* specular; //スペキュラIBL出力
#ifdef _DEBUG
	bool      show_buffer; //G-Bufferをレンダリングするか
#endif

	static const int CUBE_SIZE = 512;
	static const int MIPMAP_NUM;

	//Post-Effect
	iex2DObj* SSAO;
	bool useSSAO;
public:
	~sceneMain();
	//	初期化
	bool Initialize();
	//	更新・描画
	void Update();	//	更新
	void Render();	//	描画

	//キューブマップ作成
	//BasePoint:撮影原点
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


