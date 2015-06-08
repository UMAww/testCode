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

	Renderflg = true;

	return true;
}

sceneMain::~sceneMain()
{

	if( camera ){ delete camera; camera = nullptr; }
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

	char str[128];
	//	画面クリア
	camera -> Clear();

	if( Renderflg )
	{
		//ガンマ補正あり
		sky->Render();
		stage -> Render( shader, "test" );
		sphere -> Render( "cube_test" );

		wsprintf( str, "ガンマ補正あり" );
		IEX_DrawText( str, 10,60,200,20, 0xFFFFFF00 );
	}
	else
	{
		//ガンマ補正なし
		sky->Render();
		stage -> Render( shader, "base" );
		sphere -> Render( "cube_base" );

		wsprintf( str, "ガンマ補正なし" );
		IEX_DrawText( str, 10,60,200,20, 0xFFFFFF00 );
	}

}

//動的にキューブマップの作成
void sceneMain::CreateCubeMap()
{

	//キューブマップ
	LPDIRECT3DCUBETEXTURE9 Dynamic;
	iexSystem::Device->CreateCubeTexture( 512, 1,  D3DUSAGE_RENDERTARGET, D3DFMT_A8R8G8B8, D3DPOOL_DEFAULT, &Dynamic, NULL );
	if( !Dynamic ) return;

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

   for( int i = 0; i < 6; i++ )
   {
	   //サーフェイス指定
	   LPDIRECT3DSURFACE9 CurrentTarget, OldTarget;
	   Dynamic->GetCubeMapSurface( (D3DCUBEMAP_FACES)i, 0, &CurrentTarget );
	   CurrentTarget->Release();
	   //サーフェイスの保存
	   iexSystem::Device->GetRenderTarget( 0, &OldTarget );
	   OldTarget->Release();
	   iexSystem::Device->SetRenderTarget( 0, CurrentTarget );

	   //ビュー行列の作成
	   Matrix View;
	   LookAtLH( matView, sphere->GetPos(), LookAt[i], Up[i] );

	   //パース(必ず90度)
	   Matrix Projection;
	   PerspectiveLH( matProjection, D3DXToRadian( 90.0f ), 1.0f, 1.0f, 1000.0f );

	   //	DirectX設定
	   iexSystem::Device->SetTransform( D3DTS_PROJECTION, &matProjection );
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

	   //サーフェイスの復元
	   iexSystem::Device->SetRenderTarget( 0, OldTarget );

   }

   //テクスチャの適用
   shader->SetValue("CubeMap", Dynamic );

}

