#include	"iextreme.h"
#include	"system/system.h"

#include	"sceneMain.h"

//*****************************************************************************************************************************
//
//	グローバル変数
//
//*****************************************************************************************************************************

//キューブマップの大きさからミップマップのレベル数を算出
const int sceneMain::MIPMAP_NUM = (int)(log((double)CUBE_SIZE) / log(2.0));

//*****************************************************************************************************************************
//
//	初期化
//
//*****************************************************************************************************************************

bool sceneMain::Initialize()
{
	//	環境設定
	iexLight::SetAmbient(0x404040);
	iexLight::SetFog( 100, 100000, 0 );

	//	カメラ設定
	camera = new Camera();

	//ステージとか
	stage = new iexMesh("data/BG/stage/stage01.x");
	sky = new iexMesh("data/BG/sky/sky.x");
	sky->SetScale(0.5f);
	sky->Update();
	sphere = new ObjectManager("data/sphere.x");

	//シェーダー関係
	shader->SetValue("MaxMipMaplevel", MIPMAP_NUM);
	//キューブマップ作成
	CreateCubeMap();
	//RenderTarget
	iexSystem::GetDevice()->GetRenderTarget( 0, &back );
	screen   = new iex2DObj( iexSystem::ScreenWidth, iexSystem::ScreenHeight, IEX2D_RENDERTARGET );
	color    = new iex2DObj( iexSystem::ScreenWidth, iexSystem::ScreenHeight, IEX2D_RENDERTARGET );
	normal   = new iex2DObj( iexSystem::ScreenWidth, iexSystem::ScreenHeight, IEX2D_RENDERTARGET );
	depth    = new iex2DObj( iexSystem::ScreenWidth, iexSystem::ScreenHeight, IEX2D_RENDERTARGET );
	MR       = new iex2DObj( iexSystem::ScreenWidth, iexSystem::ScreenHeight, IEX2D_RENDERTARGET );
	light    = new iex2DObj( iexSystem::ScreenWidth, iexSystem::ScreenHeight, IEX2D_RENDERTARGET );
	specular = new iex2DObj( iexSystem::ScreenWidth, iexSystem::ScreenHeight, IEX2D_RENDERTARGET );
	IBL      = new iex2DObj( iexSystem::ScreenWidth, iexSystem::ScreenHeight, IEX2D_RENDERTARGET );
#ifdef _DEBUG
	show_buffer = false;
#endif

	//Post-Effect
	//SSAO
	SSAO    = new iex2DObj(iexSystem::ScreenWidth, iexSystem::ScreenHeight, IEX2D_RENDERTARGET);
	useSSAO = true;

	return true;
}

sceneMain::~sceneMain()
{
	DeleteObj( camera );
	DeleteObj( sky );
	DeleteObj( stage );
	DeleteObj( sphere );
	DeleteObj( screen );
	DeleteObj( color );
	DeleteObj( normal );
	DeleteObj( depth );
	DeleteObj( MR );
	DeleteObj( SSAO );
	DeleteObj( light );
	DeleteObj( specular );
	DeleteObj( IBL );
}

//*****************************************************************************************************************************
//
//		更新
//
//*****************************************************************************************************************************
void	sceneMain::Update()
{
	sphere -> Update();

	camera -> Update( Vector3( .0f, 0.5f, .0f ) );

#ifdef _DEBUG
	//「Z」キーでG-Bufferの表示切り替え
	if( KEY_Get( KEY_A ) == 3 )
	{
		show_buffer = !show_buffer;
	}
#endif
}

//*****************************************************************************************************************************
//
//		描画関連
//
//*****************************************************************************************************************************
void	sceneMain::Render()
{
	//ディファードでライティング
	DeferredRenderProc();

	//ForwardRenderProc();

	//ポストエフェクトの適用
	//PostEffectProc();
}

void sceneMain::CreateG_Buffer()
{
	color  -> RenderTarget();
	normal -> RenderTarget( 1 );
	depth  -> RenderTarget( 2 );
	MR     -> RenderTarget( 3 );

	camera -> Clear();

	shader -> SetValue("testMetalness", 0.0f );
	shader -> SetValue("testRoughness", 0.0f );
	sky    -> Render(shader, "create_gbuffer");
	shader -> SetValue("testMetalness", 0.0f );
	shader -> SetValue("testRoughness", 1.0f );
	stage  -> Render(shader, "create_gbuffer");
	sphere -> Render("create_gbuffer");

	iexSystem::GetDevice()->SetRenderTarget( 0, back );
	iexSystem::GetDevice()->SetRenderTarget( 1, NULL );
	iexSystem::GetDevice()->SetRenderTarget( 2, NULL );
	iexSystem::GetDevice()->SetRenderTarget( 3, NULL );

	shader -> SetValue("ColorMap", color );
	shader -> SetValue("NormalMap", normal );
	shader -> SetValue("DepthMap", depth );
	shader -> SetValue("MRMap", MR );

	shader2D -> SetValue("NormalMap", normal );
	shader2D -> SetValue("DepthMap", depth );

}

#ifdef _DEBUG
void sceneMain::ShowG_Buffer()
{
	if( !show_buffer ) return;

	color   -> Render(   0,   0, 320, 160, 0, 0, iexSystem::ScreenWidth, iexSystem::ScreenHeight );
	normal  -> Render( 320,   0, 320, 160, 0, 0, iexSystem::ScreenWidth, iexSystem::ScreenHeight );
	depth   -> Render( 640,   0, 320, 160, 0, 0, iexSystem::ScreenWidth, iexSystem::ScreenHeight );
	MR      -> Render( 960,   0, 320, 160, 0, 0, iexSystem::ScreenWidth, iexSystem::ScreenHeight );
	light   -> Render(   0, 160, 320, 160, 0, 0, iexSystem::ScreenWidth, iexSystem::ScreenHeight );
}
#endif

//キューブマップの作成
void sceneMain::CreateCubeMap( Vector3 BasePoint )
{
	iexSystem::BeginScene();

	LPDIRECT3DSURFACE9 OldTarget;
	//サーフェイスの保存
	iexSystem::Device->GetRenderTarget( 0, &OldTarget );
	OldTarget->Release();

	//通常キューブマップ
	LPDIRECT3DCUBETEXTURE9 DynamicCubeTex;
	iexSystem::Device->CreateCubeTexture(CUBE_SIZE, 0, D3DUSAGE_RENDERTARGET, D3DFMT_A8R8G8B8, D3DPOOL_DEFAULT, &DynamicCubeTex, NULL);
	if( !DynamicCubeTex ) return;
	
	// カメラの向きとアップベクトル
	static const int dir = 6;
	Vector3 LookAt[dir] = {
	   Vector3( 1.0f,  0.0f,  0.0f),	// +X
	   Vector3(-1.0f,  0.0f,  0.0f),	// -X
	   Vector3( 0.0f,  1.0f,  0.0f),	// +Y
	   Vector3( 0.0f, -1.0f,  0.0f),	// -Y
	   Vector3( 0.0f,  0.0f,  1.0f),	// +Z
	   Vector3( 0.0f,  0.0f, -1.0f) 	// -Z
	};
	Vector3 Up[dir] = {
	   Vector3( 0.0f,  1.0f,  0.0f),	// +X
	   Vector3( 0.0f,  1.0f,  0.0f),	// -X
	   Vector3( 0.0f,  0.0f, -1.0f),	// +Y
	   Vector3( 0.0f,  0.0f,  1.0f),	// -X
	   Vector3( 0.0f,  1.0f,  0.0f),	// +Z
	   Vector3( 0.0f,  1.0f,  0.0f),	// -Z
	};

	//パース(必ず90度)
	Matrix Projection;
	PerspectiveLH( matProjection, D3DXToRadian( 90.0f ), 1.0f, 1.0f, 1000.0f );
	iexSystem::Device->SetTransform( D3DTS_PROJECTION, &matProjection );

	for( int i = 0; i < dir; i++ )
	{
		//ビュー行列の作成
		Matrix View;
		LookAtLH( matView, BasePoint, BasePoint+LookAt[i], Up[i] );
		iexSystem::Device->SetTransform( D3DTS_VIEW, &matView );

		//通常描画用テクスチャに切り替え
		LPDIRECT3DSURFACE9 CurrentTarget;
		//ミップマップレベル回描画(1x1の分1回多くループ)
		for( int j = 0; j < MIPMAP_NUM+1; j++ )
		{
			DynamicCubeTex->GetCubeMapSurface( (D3DCUBEMAP_FACES)i, j, &CurrentTarget );
			//CurrentTarget->Release();		
			iexSystem::Device->SetRenderTarget( 0, CurrentTarget );

			//画面クリア
			camera->ClearScreen();

			//描画(静的オブジェクトだけ描画)
			sky->Render(shader,"base");
			stage->Render( shader, "base");
		}	
	}

	//サーフェイスの復元
	iexSystem::Device->SetRenderTarget( 0, OldTarget );
	
	//テクスチャの適用
	shader->SetValue("CubeMap", DynamicCubeTex );
	//キューブマップテクスチャの解放
	DynamicCubeTex->Release();

	iexSystem::EndScene();
}

void sceneMain::CreateSSAO()
{
	if( !useSSAO ) return;

	SSAO -> RenderTarget();

	camera -> Clear();

	Matrix invProj;
	D3DXMatrixInverse( &invProj, NULL, &matProjection );
	shader2D -> SetValue("InvProjection", invProj );

	SSAO -> Render( shader2D, "ssao" );

	iexSystem::Device->SetRenderTarget( 0, back );
}

void sceneMain::ForwardRenderProc()
{
	iexSystem::Device->SetRenderTarget( 0, back );

	camera -> Clear();

	sky    -> Render();
	stage  -> Render();
	sphere -> Render();
}

void sceneMain::DeferredRenderProc()
{
	CreateG_Buffer();

	Matrix invProj;
	D3DXMatrixInverse( &invProj, NULL, &matProjection );
	shader->SetValue("InvProjection", invProj );

	//ライティングの計算
	Vector3 lightpos( 5.0f, 20.0f, 10.0f );
	Vector3 lightvec( -0.5f, -2.0f, -1.0f );
	Vector3 lightcolor( 1.0f, 1.0f, 1.0f );
	float lightflux = 100000.0f;    //全光束
	DirLight( lightpos, lightvec, lightcolor, lightflux );

	//出力
	iexSystem::Device->SetRenderTarget( 0, back );
	camera->Clear();
	screen->Render( shader, "deferred");

	ShowG_Buffer();
}

void sceneMain::DirLight( Vector3 light_pos, Vector3 light_vec, Vector3 light_color, float light_flux )
{
	light->RenderTarget();

	camera->Clear();

	shader->SetValue("LightPos", light_pos );
	shader->SetValue("LightVec", light_vec);
	shader->SetValue("LightColor", light_color);
	shader->SetValue("LightFlux", light_flux);

	light->Render( shader, "dirlight" );

	iexSystem::Device->SetRenderTarget( 0, back );

	shader->SetValue("LightMap", light );
}

void sceneMain::PostEffectProc()
{
	CreateSSAO();

	SSAO->Render( 0, 0, iexSystem::ScreenWidth, iexSystem::ScreenHeight,
		          0, 0, iexSystem::ScreenWidth, iexSystem::ScreenHeight,
		          RS_MUL );
}