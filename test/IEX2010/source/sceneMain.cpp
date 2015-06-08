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
	char str[128];
	//	画面クリア
	camera -> Clear();

	if( Renderflg )
	{
		//ガンマ補正あり
		stage -> Render( shader, "test" );
		sphere -> Render( "test" );

		wsprintf( str, "ガンマ補正あり" );
		IEX_DrawText( str, 10,60,200,20, 0xFFFFFF00 );
	}
	else
	{
		//ガンマ補正なし
		stage -> Render( shader, "base" );
		sphere -> Render( "base" );

		wsprintf( str, "ガンマ補正なし" );
		IEX_DrawText( str, 10,60,200,20, 0xFFFFFF00 );
	}

}



