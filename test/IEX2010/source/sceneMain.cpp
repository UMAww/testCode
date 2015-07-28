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
#else
	stage = new iexMesh("data/BG/2_1/FIELD2_1.iMo");
#endif
	sky = new iexMesh("data/BG/sky/sky.x");
	sky->SetScale(0.5f);
	sky->Update();

	box = new Object("data/box.x");
	box -> SetPos( Vector3( .0f, 15.0f, .0f ) );
	box -> SetScale( 2.0f );

	Renderflg = true;


	//シェーダー関係
	shader->SetValue("MaxMipMaplevel", MIPMAP_NUM);
	//キューブマップ作成
	DynamicCreateCubeMap();
	//StaticCreateCubeMap("data/CubeMaps/CubeMap3SpecularHDR.dds");

	return true;
}

sceneMain::~sceneMain()
{

	if( camera ){ delete camera; camera = nullptr; }
	if( sky ){ delete sky; sky = nullptr; }
	if( stage ){ delete stage; stage = nullptr; }
	if( box ){ delete box; box = nullptr; }

}

//*****************************************************************************************************************************
//
//		更新
//
//*****************************************************************************************************************************
void	sceneMain::Update()
{
	box -> Update();

	camera -> Update( box->GetPos() );


	if( KEY_Get( KEY_ENTER ) == 3 ) Renderflg = !Renderflg;
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

	char str[1280];
	//	画面クリア
	camera -> Clear();

	if( Renderflg )
	{
		//ガンマ補正あり
		sky->Render();
		shader->SetValue("Metalness", box->GetMetalness() );
		shader->SetValue("Roughness", box->GetRoughness() );
		stage -> Render( shader, "pbr_test" );
		box -> Render( "pbr_test" );

		wsprintf( str, "ガンマ補正あり" );
		//IEX_DrawText( str, 10,60,200,20, 0xFFFFFF00 );
	}
	else
	{
		//ガンマ補正なし
		sky->Render();
		stage -> Render( shader, "base" );
		box -> Render( "base" );

		wsprintf( str, "ガンマ補正なし" );
		//IEX_DrawText( str, 10,60,200,20, 0xFFFFF//F00 );
	}

	sprintf_s( str, "Roughness:%1.3f", box->GetRoughness() );
	IEX_DrawText( str, 1000,80,2000,20, 0xFFFFFF00 );
	sprintf_s( str, "Metalness:%1.3f", box->GetMetalness() );
	IEX_DrawText( str, 1000,100,2000,20, 0xFFFFFF00 );

}

//動的にキューブマップの作成
void sceneMain::DynamicCreateCubeMap()
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
		LookAtLH( matView, box->GetPos(), box->GetPos()+LookAt[i], Up[i] );
		iexSystem::Device->SetTransform( D3DTS_VIEW, &matView );

		//通常描画用テクスチャに切り替え
		LPDIRECT3DSURFACE9 CurrentTarget;
		//ミップマップレベル回描画(1x1の分1回多くループ)
		for( int j = 0; j < MIPMAP_NUM+1; j++ )
		{
			DynamicCubeTex->GetCubeMapSurface( (D3DCUBEMAP_FACES)i, j, &CurrentTarget );
			CurrentTarget->Release();		
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