#include	"iextreme.h"
#include	"system/system.h"

#include	"sceneMain.h"

//*****************************************************************************************************************************
//
//	�O���[�o���ϐ�
//
//*****************************************************************************************************************************

//�L���[�u�}�b�v�̑傫������~�b�v�}�b�v�̃��x�������Z�o
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

	//�X�e�[�W�Ƃ�
	stage = new iexMesh("data/BG/stage/stage01.x");
	sky = new iexMesh("data/BG/sky/sky.x");
	sky->SetScale(0.5f);
	sky->Update();
	sphere = new ObjectManager("data/sphere.x");

	//�V�F�[�_�[�֌W
	shader->SetValue("MaxMipMaplevel", MIPMAP_NUM);
	//�L���[�u�}�b�v�쐬
	CreateCubeMap();
	//RenderTarget
	iexSystem::GetDevice()->GetRenderTarget( 0, &back );
	screen   = new iex2DObj( iexSystem::ScreenWidth, iexSystem::ScreenHeight, IEX2D_RENDERTARGET );
	color    = new iex2DObj( iexSystem::ScreenWidth, iexSystem::ScreenHeight, IEX2D_RENDERTARGET );
	normal   = new iex2DObj( iexSystem::ScreenWidth, iexSystem::ScreenHeight, IEX2D_RENDERTARGET );
	depth    = new iex2DObj( iexSystem::ScreenWidth, iexSystem::ScreenHeight, IEX2D_FLOAT );
	MR       = new iex2DObj( iexSystem::ScreenWidth, iexSystem::ScreenHeight, IEX2D_RENDERTARGET );
	light    = new iex2DObj( iexSystem::ScreenWidth, iexSystem::ScreenHeight, IEX2D_RENDERTARGET );
	specular = new iex2DObj( iexSystem::ScreenWidth, iexSystem::ScreenHeight, IEX2D_RENDERTARGET );


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
}

//*****************************************************************************************************************************
//
//		�X�V
//
//*****************************************************************************************************************************
void	sceneMain::Update()
{
	sphere -> Update();

	camera -> Update( Vector3( .0f, 0.5f, .0f ) );
}

//*****************************************************************************************************************************
//
//		�`��֘A
//
//*****************************************************************************************************************************
void	sceneMain::Render()
{
	//�f�B�t�@�[�h�Ń��C�e�B���O
	DeferredRenderProc();

	//�|�X�g�G�t�F�N�g�̓K�p
	//PostEffectProc();

	//ForwardRenderProc();
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

//�L���[�u�}�b�v�̍쐬
void sceneMain::CreateCubeMap( Vector3 BasePoint )
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
		LookAtLH( matView, BasePoint, BasePoint+LookAt[i], Up[i] );
		iexSystem::Device->SetTransform( D3DTS_VIEW, &matView );

		//�ʏ�`��p�e�N�X�`���ɐ؂�ւ�
		LPDIRECT3DSURFACE9 CurrentTarget;
		//�~�b�v�}�b�v���x����`��(1x1�̕�1�񑽂����[�v)
		for( int j = 0; j < MIPMAP_NUM+1; j++ )
		{
			DynamicCubeTex->GetCubeMapSurface( (D3DCUBEMAP_FACES)i, j, &CurrentTarget );
			//CurrentTarget->Release();		
			iexSystem::Device->SetRenderTarget( 0, CurrentTarget );

			//��ʃN���A
			camera->ClearScreen();

			//�`��(�ÓI�I�u�W�F�N�g�����`��)
			sky->Render(shader,"base");
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

	//���C�e�B���O�̌v�Z
	Vector3 lightvec( -0.5f, -2.0f, -1.0f );
	Vector3 lightcolor( 1.0f, 1.0f, 1.0f );
	DirLight( lightvec, lightcolor );

	//����
	screen->RenderTarget();
	camera->Clear();
	screen->Render( shader, "deferred");

	//�o��
	iexSystem::Device->SetRenderTarget( 0, back );
	camera->Clear();
	screen->Render();
	
#ifdef _DEBUG
	//ShowG_Buffer
	color->Render( 0, 0, 320, 160, 0, 0, iexSystem::ScreenWidth, iexSystem::ScreenHeight );
	normal->Render( 320, 0, 320, 160, 0, 0, iexSystem::ScreenWidth, iexSystem::ScreenHeight );
	specular->Render( 640, 0, 320, 160, 0, 0, iexSystem::ScreenWidth, iexSystem::ScreenHeight );
	light->Render( 960, 0, 320, 160, 0, 0, iexSystem::ScreenWidth, iexSystem::ScreenHeight );
#endif
}

void sceneMain::DirLight( Vector3 light_vec, Vector3 light_color )
{
	light->RenderTarget();
	specular->RenderTarget( 1 );

	camera->Clear();

	light->Render( shader, "dirlight" );

	shader->SetValue("LightVec", light_vec );

	iexSystem::Device->SetRenderTarget( 0, back );
	iexSystem::Device->SetRenderTarget( 1, NULL );

	shader->SetValue("LightMap", light );
	shader->SetValue("SpecularMap", specular );
}

void sceneMain::PostEffectProc()
{
	CreateSSAO();

	SSAO->Render( 0, 160, 320, 160, 0, 0, iexSystem::ScreenWidth, iexSystem::ScreenHeight );
}