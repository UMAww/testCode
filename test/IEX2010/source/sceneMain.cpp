#include	"iextreme.h"
#include	"system/system.h"

#include	"sceneMain.h"

//*****************************************************************************************************************************
//
//	�O���[�o���ϐ�
//
//*****************************************************************************************************************************

#define ST1

const int sceneMain::MIPMAP_NUM = (int)(log((double)CUBE_SIZE) / log(2.0));

//*****************************************************************************************************************************
//
//	������
//
//*****************************************************************************************************************************

bool sceneMain::Initialize()
{
	//	���ݒ�
	iexLight::SetAmbient(0x404040);
	iexLight::SetFog( 100, 100000, 0 );

	Vector3 dir( .0f, -8.0f, -5.0f );
	shader->SetValue("DirLightVec", dir*100.0f );
	dir.Normalize();
	iexLight::DirLight( shader, 0, &dir, 0.8f, 0.8f, 0.8f );

	//	�J�����ݒ�
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


	//�V�F�[�_�[�֌W
	shader->SetValue("MaxMipMaplevel", MIPMAP_NUM);
	//�L���[�u�}�b�v�쐬
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
//		�X�V
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
//		�`��֘A
//
//*****************************************************************************************************************************
void	sceneMain::Render()
{
	//�L���[�u�}�b�v�쐬
	//DynamicCreateCubeMap();

	char str[1280];
	//	��ʃN���A
	camera -> Clear();

	if( Renderflg )
	{
		//�K���}�␳����
		sky->Render();
		shader->SetValue("Metalness", box->GetMetalness() );
		shader->SetValue("Roughness", box->GetRoughness() );
		stage -> Render( shader, "pbr_test" );
		box -> Render( "pbr_test" );

		wsprintf( str, "�K���}�␳����" );
		//IEX_DrawText( str, 10,60,200,20, 0xFFFFFF00 );
	}
	else
	{
		//�K���}�␳�Ȃ�
		sky->Render();
		stage -> Render( shader, "base" );
		box -> Render( "base" );

		wsprintf( str, "�K���}�␳�Ȃ�" );
		//IEX_DrawText( str, 10,60,200,20, 0xFFFFF//F00 );
	}

	sprintf_s( str, "Roughness:%1.3f", box->GetRoughness() );
	IEX_DrawText( str, 1000,80,2000,20, 0xFFFFFF00 );
	sprintf_s( str, "Metalness:%1.3f", box->GetMetalness() );
	IEX_DrawText( str, 1000,100,2000,20, 0xFFFFFF00 );

}

//���I�ɃL���[�u�}�b�v�̍쐬
void sceneMain::DynamicCreateCubeMap()
{

	iexSystem::BeginScene();

	LPDIRECT3DSURFACE9 OldTarget;
	//�T�[�t�F�C�X�̕ۑ�
	iexSystem::Device->GetRenderTarget( 0, &OldTarget );
	OldTarget->Release();

	//�ʏ�L���[�u�}�b�v
	LPDIRECT3DCUBETEXTURE9 DynamicCubeTex;
	iexSystem::Device->CreateCubeTexture(CUBE_SIZE, 0, D3DUSAGE_RENDERTARGET, D3DFMT_A8R8G8B8, D3DPOOL_DEFAULT, &DynamicCubeTex, NULL);
	if( !DynamicCubeTex ) return;
	
	// �J�����̌����ƃA�b�v�x�N�g��
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

	//�p�[�X(�K��90�x)
	Matrix Projection;
	PerspectiveLH( matProjection, D3DXToRadian( 90.0f ), 1.0f, 1.0f, 1000.0f );
	iexSystem::Device->SetTransform( D3DTS_PROJECTION, &matProjection );

	for( int i = 0; i < dir; i++ )
	{
		//�r���[�s��̍쐬
		Matrix View;
		LookAtLH( matView, box->GetPos(), box->GetPos()+LookAt[i], Up[i] );
		iexSystem::Device->SetTransform( D3DTS_VIEW, &matView );

		//�ʏ�`��p�e�N�X�`���ɐ؂�ւ�
		LPDIRECT3DSURFACE9 CurrentTarget;
		//�~�b�v�}�b�v���x����`��(1x1�̕�1�񑽂����[�v)
		for( int j = 0; j < MIPMAP_NUM+1; j++ )
		{
			DynamicCubeTex->GetCubeMapSurface( (D3DCUBEMAP_FACES)i, j, &CurrentTarget );
			CurrentTarget->Release();		
			iexSystem::Device->SetRenderTarget( 0, CurrentTarget );

			//��ʃN���A
			camera->ClearScreen();

			//�`��
			sky->Render(shader,"base");
			shader->SetValue("Metalness", 0.0f );
			shader->SetValue("Roughness", 1.0f );
			stage->Render( shader, "base");
		}
	
	}

	//�T�[�t�F�C�X�̕���
	iexSystem::Device->SetRenderTarget( 0, OldTarget );
	
	//�e�N�X�`���̓K�p
	shader->SetValue("CubeMap", DynamicCubeTex );
	//�L���[�u�}�b�v�e�N�X�`���̉��
	DynamicCubeTex->Release();

	iexSystem::EndScene();

}

//�ÓI�ɃL���[�u�}�b�v����
void sceneMain::StaticCreateCubeMap( char* filename )
{
	LPDIRECT3DCUBETEXTURE9 StaticCubeTex;
	D3DXCreateCubeTextureFromFile( iexSystem::Device, filename, &StaticCubeTex );

	shader->SetValue("CubeMap", StaticCubeTex );

	StaticCubeTex->Release();
}