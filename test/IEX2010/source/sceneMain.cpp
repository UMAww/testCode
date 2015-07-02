#include	"iextreme.h"
#include	"system/system.h"

#include	"sceneMain.h"


//*****************************************************************************************************************************
//
//	グローバル変数
//
//*****************************************************************************************************************************


//*****************************************************************************************************************************
//
//	初期化
//
//*****************************************************************************************************************************

bool sceneMain::Initialize()
{
	//	環境設定
	iexLight::SetAmbient(0x404040);
	iexLight::SetFog( 800, 1000, 0 );

	Vector3 dir( 2.0f, 8.0f, -3.0f );
	shader->SetValue("DirLightVec", dir*100.0f );
	dir.Normalize();
	iexLight::DirLight( shader, 0, &dir, 0.8f, 0.8f, 0.8f );

	//	カメラ設定
	camera = new Camera();

	stage = new iexMesh("data/BG/stage/stage01.x");
	sky = new iexMesh("data/BG/sky/sky.imo");

	sphere = new Object("data/sphere.x");
	sphere -> SetPos( Vector3( .0f, 5.0f, .0f ) );
	sphere -> SetScale( 0.01f );

	normal = new iex2DObj( 512, 512, IEX2D_RENDERTARGET );

	Renderflg = true;

	return true;
}

sceneMain::~sceneMain()
{

	if( camera ){ delete camera; camera = nullptr; }
	if( sky ){ delete sky; sky = nullptr; }
	if( stage ){ delete stage; stage = nullptr; }
	if( sphere ){ delete sphere; sphere = nullptr; }

}

//*****************************************************************************************************************************
//
//		更新
//
//*****************************************************************************************************************************
void	sceneMain::Update()
{
	sphere -> Update();

	camera -> Update( sphere->GetPos() );


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
	CreateCubeMap();

	char str[1280];
	//	画面クリア
	camera -> Clear();

	if( Renderflg )
	{
		//ガンマ補正あり
		sky->Render();
		shader->SetValue("Metalness", .0f );
		shader->SetValue("Roughness", 1.0f );
		stage -> Render( shader, "test" );
		sphere -> Render( "test" );

		wsprintf( str, "ガンマ補正あり" );
		IEX_DrawText( str, 10,60,200,20, 0xFFFFFF00 );
	}
	else
	{
		//ガンマ補正なし
		sky->Render();
		stage -> Render( shader, "base" );
		sphere -> Render( "base" );

		wsprintf( str, "ガンマ補正なし" );
		IEX_DrawText( str, 10,60,200,20, 0xFFFFFF00 );
	}

	//normal->Render( 0, 0, 256, 256, 0, 0, 512, 512, shader2D, "blur" );

	sprintf_s( str, "Roughness:%1.3f", sphere->GetRoughness() );
	IEX_DrawText( str, 1000,80,2000,20, 0xFFFFFF00 );
	sprintf_s( str, "Metalness:%1.3f", sphere->GetMetalness() );
	IEX_DrawText( str, 1000,100,2000,20, 0xFFFFFF00 );

}

//動的にキューブマップの作成
void sceneMain::CreateCubeMap()
{
	LPDIRECT3DSURFACE9 OldTarget;
	//サーフェイスの保存
	iexSystem::Device->GetRenderTarget( 0, &OldTarget );
	//OldTarget->Release();

	//通常キューブマップ
	LPDIRECT3DCUBETEXTURE9 DynamicCubeTex;
	iexSystem::Device->CreateCubeTexture( 512, 1,  D3DUSAGE_RENDERTARGET, D3DFMT_A8R8G8B8, D3DPOOL_DEFAULT, &DynamicCubeTex, NULL );
	if( !DynamicCubeTex ) return;
	
	// カメラの向きとアップベクトル
	Vector3 LookAt[6] = {
	   Vector3( 1.0f,  0.0f,  0.0f),	// +X
	   Vector3(-1.0f,  0.0f,  0.0f),	// -X
	   Vector3( 0.0f,  1.0f,  0.0f),	// +Y
	   Vector3( 0.0f, -1.0f,  0.0f),	// -Y
	   Vector3( 0.0f,  0.0f,  1.0f),	// +Z
	   Vector3( 0.0f,  0.0f, -1.0f) 	// -Z
	};
	Vector3 Up[6] = {
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

	for( int i = 0; i < 6; i++ )
	{
		//通常描画用テクスチャに切り替え
		normal->RenderTarget();

		//ビュー行列の作成
		Matrix View;
		LookAtLH( matView, sphere->GetPos(), sphere->GetPos()+LookAt[i], Up[i] );
		iexSystem::Device->SetTransform( D3DTS_VIEW, &matView );

		//画面クリア
		camera->ClearScreen();

		//描画
		if( Renderflg )
		{
		   //ガンマ補正あり
		   sky->Render();
		   stage->Render( shader, "test");
		}
		else
		{
		   //ガンマ補正なし
		   sky->Render();
		   stage->Render( shader, "base");
		}
		iexSystem::Device->SetRenderTarget( 0, OldTarget );

		//通常キューブマップ用サーフェイス指定
		LPDIRECT3DSURFACE9 CurrentTarget;
		DynamicCubeTex->GetCubeMapSurface( (D3DCUBEMAP_FACES)i, 0, &CurrentTarget );
		CurrentTarget->Release();		
		iexSystem::Device->SetRenderTarget( 0, CurrentTarget );
		
		//画面クリア
		camera->ClearScreen();
		
		//描画
		shader2D->SetValue("offset", 10.0f * ( 1.0f - sphere->GetRoughness() ));
		normal->Render( 0, 0, 512, 512, 0, 0, 512, 512, shader2D, "blur" );
	
	}

	//サーフェイスの復元
	iexSystem::Device->SetRenderTarget( 0, OldTarget );
	
	//テクスチャの適用
	shader->SetValue("CubeMap", DynamicCubeTex );
	//キューブマップテクスチャの解放
	DynamicCubeTex->Release();

}

