#include	"iextreme.h"
#include	"system/system.h"

#include	"sceneMain.h"


//*****************************************************************************************************************************
//
//	�O���[�o���ϐ�
//
//*****************************************************************************************************************************


//*****************************************************************************************************************************
//
//	������
//
//*****************************************************************************************************************************

bool sceneMain::Initialize()
{
	//	���ݒ�
	iexLight::SetAmbient(0x404040);
	iexLight::SetFog( 800, 1000, 0 );

	Vector3 dir( 2.0f, 8.0f, -3.0f );
	shader->SetValue("DirLightVec", dir*100.0f );
	dir.Normalize();
	iexLight::DirLight( shader, 0, &dir, 0.8f, 0.8f, 0.8f );

	//	�J�����ݒ�
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
//		�X�V
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
//		�`��֘A
//
//*****************************************************************************************************************************
void	sceneMain::Render()
{

	//�L���[�u�}�b�v�쐬
	CreateCubeMap();

	char str[1280];
	//	��ʃN���A
	camera -> Clear();

	if( Renderflg )
	{
		//�K���}�␳����
		sky->Render();
		shader->SetValue("Metalness", .0f );
		shader->SetValue("Roughness", 1.0f );
		stage -> Render( shader, "test" );
		sphere -> Render( "test" );

		wsprintf( str, "�K���}�␳����" );
		IEX_DrawText( str, 10,60,200,20, 0xFFFFFF00 );
	}
	else
	{
		//�K���}�␳�Ȃ�
		sky->Render();
		stage -> Render( shader, "base" );
		sphere -> Render( "base" );

		wsprintf( str, "�K���}�␳�Ȃ�" );
		IEX_DrawText( str, 10,60,200,20, 0xFFFFFF00 );
	}

	//normal->Render( 0, 0, 256, 256, 0, 0, 512, 512, shader2D, "blur" );

	sprintf_s( str, "Roughness:%1.3f", sphere->GetRoughness() );
	IEX_DrawText( str, 1000,80,2000,20, 0xFFFFFF00 );
	sprintf_s( str, "Metalness:%1.3f", sphere->GetMetalness() );
	IEX_DrawText( str, 1000,100,2000,20, 0xFFFFFF00 );

}

//���I�ɃL���[�u�}�b�v�̍쐬
void sceneMain::CreateCubeMap()
{
	LPDIRECT3DSURFACE9 OldTarget;
	//�T�[�t�F�C�X�̕ۑ�
	iexSystem::Device->GetRenderTarget( 0, &OldTarget );
	//OldTarget->Release();

	//�ʏ�L���[�u�}�b�v
	LPDIRECT3DCUBETEXTURE9 DynamicCubeTex;
	iexSystem::Device->CreateCubeTexture( 512, 1,  D3DUSAGE_RENDERTARGET, D3DFMT_A8R8G8B8, D3DPOOL_DEFAULT, &DynamicCubeTex, NULL );
	if( !DynamicCubeTex ) return;
	
	// �J�����̌����ƃA�b�v�x�N�g��
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

	//�p�[�X(�K��90�x)
	Matrix Projection;
	PerspectiveLH( matProjection, D3DXToRadian( 90.0f ), 1.0f, 1.0f, 1000.0f );
	iexSystem::Device->SetTransform( D3DTS_PROJECTION, &matProjection );

	for( int i = 0; i < 6; i++ )
	{
		//�ʏ�`��p�e�N�X�`���ɐ؂�ւ�
		normal->RenderTarget();

		//�r���[�s��̍쐬
		Matrix View;
		LookAtLH( matView, sphere->GetPos(), sphere->GetPos()+LookAt[i], Up[i] );
		iexSystem::Device->SetTransform( D3DTS_VIEW, &matView );

		//��ʃN���A
		camera->ClearScreen();

		//�`��
		if( Renderflg )
		{
		   //�K���}�␳����
		   sky->Render();
		   stage->Render( shader, "test");
		}
		else
		{
		   //�K���}�␳�Ȃ�
		   sky->Render();
		   stage->Render( shader, "base");
		}
		iexSystem::Device->SetRenderTarget( 0, OldTarget );

		//�ʏ�L���[�u�}�b�v�p�T�[�t�F�C�X�w��
		LPDIRECT3DSURFACE9 CurrentTarget;
		DynamicCubeTex->GetCubeMapSurface( (D3DCUBEMAP_FACES)i, 0, &CurrentTarget );
		CurrentTarget->Release();		
		iexSystem::Device->SetRenderTarget( 0, CurrentTarget );
		
		//��ʃN���A
		camera->ClearScreen();
		
		//�`��
		shader2D->SetValue("offset", 10.0f * ( 1.0f - sphere->GetRoughness() ));
		normal->Render( 0, 0, 512, 512, 0, 0, 512, 512, shader2D, "blur" );
	
	}

	//�T�[�t�F�C�X�̕���
	iexSystem::Device->SetRenderTarget( 0, OldTarget );
	
	//�e�N�X�`���̓K�p
	shader->SetValue("CubeMap", DynamicCubeTex );
	//�L���[�u�}�b�v�e�N�X�`���̉��
	DynamicCubeTex->Release();

}

