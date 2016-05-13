#ifndef _TEXTURES_
#define _TEXTURES_

//------------------------------------------------------
//		テクスチャサンプラー	
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

texture ColorMap;  //  Deferredで使うColorMap
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

texture NormalMap;	//	法線マップテクスチャ
sampler NormalSamp = sampler_state
{
	Texture = <NormalMap>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = NONE;

	AddressU = Wrap;
	AddressV = Wrap;
};

texture SpecularMap;	//	Specularテクスチャ
sampler SpecularSamp = sampler_state
{
	Texture = <SpecularMap>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = NONE;

	AddressU = Wrap;
	AddressV = Wrap;
};

texture MetalMap;  //  メタルネスマップ
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

texture RoughnessMap;  //  ラフネスマップ
sampler RoughnessSamp = sampler_state
{
	Texture = <RoughnessMap>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = NONE;

	AddressU = Wrap;
	AddressV = Wrap;
};

//最大ミップマップレベル
int MaxMipMaplevel = 0;
textureCUBE CubeMap;	//キューブマップテクスチャ
samplerCUBE CubeSamp = sampler_state
{
	Texture = <CubeMap>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
};

texture MRMap;    //Deferred用MetalnessとRoughnessを格納するテクスチャ
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