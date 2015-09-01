#include	"iextreme.h"
#include	"system/system.h"

#include	"sceneMain.h"

//*****************************************************************************************************************************
//
//	グローバル変数
//
//*****************************************************************************************************************************

#define ST1

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

	Vector3 dir( .0f, -8.0f, -5.0f );
	shader->SetValue("DirLightVec", dir*100.0f );
	dir.Normalize();
	iexLight::DirLight( shader, 0, &dir, 0.8f, 0.8f, 0.8f );

	//	カメラ設定
	camera = new Camera();

#ifdef ST1
	stage = new iexMesh("data/BG/stage/stage01.x");
	sky = new iexMesh("data/BG/sky/sky.x");
	sky->SetScale(0.5f);
#else
	stage = new iexMesh("data/BG/2_1/FIELD2_1.iMo");
	sky = new iexMesh("data/BG/sky/3ste_sky.imo");
	sky->SetScale(0.1f);
#endif
	sky->Update();

	box = new Object("data/box.x");
	box -> SetPos( Vector3( .0f, 5.0f, .0f ) );
	box -> SetScale( 2.0f );
	
	sphere = new Object("data/sphere.x");
	sphere -> SetPos( Vector3( 10.0f, 5.0f, .0f ) );
	sphere -> SetScale( 0.05f );

	Renderflg = true;

	//シェーダー関係
	shader->SetValue("MaxMipMaplevel", MIPMAP_NUM);
	//キューブマップ作成
	CreateCubeMap();
	//RenderTarget
	iexSystem::GetDevice()->GetRenderTarget( 0, &back );
	screen = new iex2DObj( iexSystem::ScreenWidth, iexSystem::ScreenHeight, IEX2D_RENDERTARGET );
	color = new iex2DObj(iexSystem::ScreenWidth, iexSystem::ScreenHeight, IEX2D_RENDERTARGET);
	normal = new iex2DObj(iexSystem::ScreenWidth, iexSystem::ScreenHeight, IEX2D_RENDERTARGET);
	Depth = new iex2DObj(iexSystem::ScreenWidth, iexSystem::ScreenHeight, IEX2D_FLOAT );
	MR = new iex2DObj(iexSystem::ScreenWidth, iexSystem::ScreenHeight, IEX2D_RENDERTARGET);

	light_index = 0;

	//Post-Effect
	//SSAO
	SSAO = new iex2DObj(iexSystem::ScreenWidth, iexSystem::ScreenHeight, IEX2D_RENDERTARGET);

	return true;
}

sceneMain::~sceneMain()
{

	DeleteObj( camera );
	DeleteObj( sky );
	DeleteObj( stage );
	DeleteObj( box );
	DeleteObj( sphere );
	DeleteObj( screen );
	DeleteObj( color );
	DeleteObj( normal );
	DeleteObj( Depth );
	DeleteObj( MR );
	DeleteObj( SSAO );

}

//*****************************************************************************************************************************
//
//		更新
//
//*****************************************************************************************************************************
void	sceneMain::Update()
{
	box -> Update();
	sphere -> Update();

	camera -> Update( sphere->GetPos() );

	if( KEY_Get( KEY_ENTER ) == 3 ) Renderflg = !Renderflg;

	if( KEY_Get( KEY_SPACE ) == 3 ) AddPoint_Light( Vector3( rand()%50, 2.0f, rand()%50 ), Vector3( rand()%2, rand()%2, rand()%2 ), 10.0f );
}

//*****************************************************************************************************************************
//
//		描画関連
//
//*****************************************************************************************************************************
void	sceneMain::Render()
{
	//キューブマップ作成
	//DynamicCreateCubeMap();

	CreateG_Buffer();

	CreateSSAO();

	char str[1280];
	//	画面クリア
	camera -> Clear();

	shader -> SetValue("pLight_Num", light_index );
	shader -> SetValue("pLight_Pos", pLight_Pos, light_index );
	shader -> SetValue("pLight_Color", pLight_Color, light_index );
	shader -> SetValue("pLight_Range", pLight_Range, light_index );

	if( Renderflg )
	{
		//Deferred
		screen -> Render( 0, 0, iexSystem::ScreenWidth, iexSystem::ScreenHeight, 0, 0, iexSystem::ScreenWidth, iexSystem::ScreenHeight, shader,"Deferred");

		//PostEffect
		SSAO -> Render(0, 0, iexSystem::ScreenWidth, iexSystem::ScreenHeight, 0, 0, iexSystem::ScreenWidth, iexSystem::ScreenHeight, RS_MUL, 0xFFFFFFFF);

		//G-Buffer
		color -> Render( 0,0,320,180,0,0,1280,720 );
		normal -> Render( 320,0,320,180,0,0,1280,720 );
		Depth -> Render( 640,0,320,180,0,0,1280,720 );
		MR -> Render( 960, 0, 320,  180, 0, 0, 1280, 720 );
		SSAO -> Render( 0, 180, 320, 180, 0, 0, 1280, 720 );
	}
	else
	{
		//Forward
		sky->Render();
		shader->SetValue("Metalness", 0.0f);
		shader->SetValue("Roughness", 1.0f);
		stage->Render(shader, "pbr_test");
		box->Render("pbr_test");
		sphere->Render("pbr_test");

		//PostEffect
		SSAO -> Render(0, 0, iexSystem::ScreenWidth, iexSystem::ScreenHeight, 0, 0, iexSystem::ScreenWidth, iexSystem::ScreenHeight, RS_MUL, 0xFFFFFFFF);
	}

#ifdef _DEBUG
	sprintf_s( str, "Roughness:%1.3f", box->GetRoughness() );
	IEX_DrawText( str, 1000,80,2000,20, 0xFFFFFF00 );
	sprintf_s( str, "Metalness:%1.3f", box->GetMetalness() );
	IEX_DrawText( str, 1000,100,2000,20, 0xFFFFFF00 );
#endif

}

void sceneMain::CreateG_Buffer()
{
	color -> RenderTarget();
	normal -> RenderTarget( 1 );
	Depth -> RenderTarget( 2 );
	MR -> RenderTarget( 3 );

	camera -> Clear();

	sky->Render();
	shader->SetValue("Metalness", 0.0f);
	shader->SetValue("Roughness", 1.0f);
	stage->Render(shader, "create_gbuffer");
	box->Render("create_gbuffer");
	sphere->Render("create_gbuffer");

	iexSystem::GetDevice()->SetRenderTarget( 0, back );
	iexSystem::GetDevice()->SetRenderTarget( 1, NULL );
	iexSystem::GetDevice()->SetRenderTarget( 2, NULL );
	iexSystem::GetDevice()->SetRenderTarget( 3, NULL );

	shader -> SetValue("ColorMap", color );
	shader -> SetValue("NormalMap", normal );
	shader -> SetValue("DepthMap", Depth );
	shader -> SetValue("MRMap", MR );

	shader2D -> SetValue("NormalMap", normal );
	shader2D -> SetValue("DepthMap", Depth );

}

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

			//描画
			sky->Render(shader,"base");
			shader->SetValue("Metalness", 0.0f );
			shader->SetValue("Roughness", 1.0f );
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

//静的にキューブマップ生成
void sceneMain::StaticCreateCubeMap( char* filename )
{
	LPDIRECT3DCUBETEXTURE9 StaticCubeTex;
	D3DXCreateCubeTextureFromFile( iexSystem::Device, filename, &StaticCubeTex );

	shader->SetValue("CubeMap", StaticCubeTex );

	StaticCubeTex->Release();
}

void sceneMain::CreateSSAO()
{
	SSAO -> RenderTarget();

	camera -> Clear();

	Matrix invProj;
	D3DXMatrixInverse( &invProj, NULL, &matProjection );
	shader -> SetValue("InvProjection", invProj );
	shader2D -> SetValue("InvProjection", invProj );

	SSAO -> Render( shader2D, "ssao" );

	iexSystem::GetDevice()->SetRenderTarget( 0, back );

}

void sceneMain::AddPoint_Light( const Vector3& pos, const Vector3& color, float range )
{
	//
	if( light_index == PLIGHT_NUM ) return;

	pLight_Pos[light_index] = pos;
	pLight_Color[light_index] = color;
	pLight_Range[light_index] = range;

	light_index++;
}

void sceneMain::DelPoint_Light()
{
	light_index--;
	if( light_index < 0 ) light_index = 0;
}