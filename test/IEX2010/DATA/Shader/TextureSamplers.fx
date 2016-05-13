#ifndef _TEXTURES_
#define _TEXTURES_

//------------------------------------------------------
//		�e�N�X�`���T���v���[	
//------------------------------------------------------
texture Texture;
sampler DecaleSamp = sampler_state
{
	Texture = <Texture>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = NONE;

	AddressU = Wrap;
	AddressV = Wrap;
};

texture ColorMap;  //  Deferred�Ŏg��ColorMap
sampler ColorSamp = sampler_state
{
	Texture = <ColorMap>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = NONE;

	AddressU = Border;
	AddressV = Border;
	BorderColor = float4(.0f, .0f, .0f, 1.0f);
};

texture NormalMap;	//	�@���}�b�v�e�N�X�`��
sampler NormalSamp = sampler_state
{
	Texture = <NormalMap>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = NONE;

	AddressU = Wrap;
	AddressV = Wrap;
};

texture SpecularMap;	//	Specular�e�N�X�`��
sampler SpecularSamp = sampler_state
{
	Texture = <SpecularMap>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = NONE;

	AddressU = Wrap;
	AddressV = Wrap;
};

texture MetalMap;  //  ���^���l�X�}�b�v
sampler MetalSamp = sampler_state
{
	Texture = <MetalMap>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = NONE;

	AddressU = Wrap;
	AddressV = Wrap;
};

texture DepthMap;
sampler DepthSamp = sampler_state
{
	Texture = <DepthMap>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = NONE;

	AddressU = Border;
	AddressV = Border;
	BorderColor = float4(.0f, .0f, .0f, 1.0f);
};

texture RoughnessMap;  //  ���t�l�X�}�b�v
sampler RoughnessSamp = sampler_state
{
	Texture = <RoughnessMap>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = NONE;

	AddressU = Wrap;
	AddressV = Wrap;
};

//�ő�~�b�v�}�b�v���x��
int MaxMipMaplevel = 0;
textureCUBE CubeMap;	//�L���[�u�}�b�v�e�N�X�`��
samplerCUBE CubeSamp = sampler_state
{
	Texture = <CubeMap>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
};

texture MRMap;    //Deferred�pMetalness��Roughness���i�[����e�N�X�`��
sampler MRSamp = sampler_state
{
	Texture = <MRMap>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = NONE;

	AddressU = Border;
	AddressV = Border;
	BorderColor = float4(.0f, .0f, .0f, 1.0f);
};

texture LightMap;    //LightMap
sampler LightSamp = sampler_state
{
	Texture = <LightMap>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = NONE;

	AddressU = Border;
	AddressV = Border;
	BorderColor = float4(.0f, .0f, .0f, 1.0f);
};

texture IBLMap;
sampler IBLSamp = sampler_state
{
	Texture = <IBLMap>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = NONE;

	AddressU = Border;
	AddressV = Border;
	BorderColor = float4(.0f, .0f, .0f, 1.0f);
};

#endif