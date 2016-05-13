#include"Utility.fx"
#include"TextureSamplers.fx"

//------------------------------------------------------
//		���_�t�H�[�}�b�g
//------------------------------------------------------
struct VS_2D
{
    float4 Pos		: POSITION;
    float4 Color	: COLOR0;
    float2 Tex		: TEXCOORD0;
};

float4 PS_Basic( float2 Tex : TEXCOORD0 ) : COLOR0
{
	return tex2D( DecaleSamp, Tex );
}

technique base
{
	pass P0
	{
		AlphaBlendEnable = true;
		BlendOp = Add;
		SrcBlend = SrcAlpha;
		DestBlend = One;
		CullMode = None;
		ZEnable = false;

		PixelShader  = compile ps_3_0 PS_Basic();
	}
}

//********************************************************************
//																									
//		Blur
//
//********************************************************************

float2 offset = { 1.0f / 1280.0f, 1.0f / 720.0f };

float4 PS_Blur( float2 Tex : TEXCOORD0 ) : COLOR0
{
	float4 Out;

	//����
	Out = tex2D(DecaleSamp,Tex) * .2f;
	//�E
	Out += tex2D(DecaleSamp,float2(Tex.x + offset.x,Tex.y)) * .1f;
	//��
	Out += tex2D(DecaleSamp,float2(Tex.x - offset.x,Tex.y)) * .1f;
	//��
	Out += tex2D(DecaleSamp,float2(Tex.x,Tex.y - offset.y)) * .1f;
	//��
	Out += tex2D(DecaleSamp,float2(Tex.x,Tex.y + offset.y)) * .1f;
	//����
	Out += tex2D(DecaleSamp,float2(Tex.x - offset.x,Tex.y - offset.y)) * .1f;
	//����
	Out += tex2D(DecaleSamp,float2(Tex.x - offset.x,Tex.y + offset.y)) * .1f;
	//�E��
	Out += tex2D(DecaleSamp,float2(Tex.x + offset.x,Tex.y - offset.y)) * .1f;
	//�E��
	Out += tex2D(DecaleSamp,float2(Tex.x + offset.x,Tex.y + offset.y)) * .1f;

	Out.a = 1.0f;

	return Out;
}

technique blur
{
	pass P0
	{
		AlphaBlendEnable = true;
		BlendOp = Add;
		SrcBlend = SrcAlpha;
		DestBlend = One;
		CullMode = None;
		ZEnable = false;

		PixelShader  = compile ps_3_0 PS_Blur();
	}
}

//********************************************************************
//																									
//		SSAO(ScreenSpaceAmbientOcclusion)
//
//********************************************************************

const int NUM_SAMPLES = 16;
float HemRadius = .5f;	//����p�̔����̔��a
float Zfar = .2f;		//����p�̐[�x����max
float AOPower = 3.0f;	//�A�̋��x

//�P�ʋ����̃����_���ȃx�N�g��
const float3 SphereArray[16] = {
	float3(  0.53812504f ,  0.18565957f  , -0.43192f ),
	float3(  0.13790712f ,  0.24864247f  ,  0.44301823f ),
	float3(  0.33715037f ,  0.56794053f  , -0.005789503f ),
	float3( -0.6999805f  , -0.04511441f  , -0.0019965635f ),
	float3(  0.06896307f , -0.15983082f  , -0.85477847f ),
	float3(  0.056099437f,  0.006954967f , -0.1843352f ),
	float3( -0.014653638f,  0.14027752f  ,  0.0762037f ),
	float3(  0.010019933f, -0.1924225f   , -0.034443386f),
	float3( -0.35775623f , -0.5301969f   , -0.43581226f),
	float3( -0.3169221f  ,  0.106360726f ,  0.015860917f),
	float3(  0.010350345f, -0.58698344f  ,  0.0046293875f),
	float3( -0.08972908f , -0.49408212f  ,  0.3287904f),
	float3(  0.7119986f  , -0.0154690035f, -0.09183723f),
	float3( -0.053382345f,  0.059675813f , -0.5411899f),
	float3(  0.035267662f, -0.063188605f ,  0.54602677f),
	float3( -0.47761092f ,  0.2847911f   , -0.0271716f)
};

float4 PS_SSAO( float2 UV : TEXCOORD0 ) : COLOR0
{
	float4 Out = 0;

	//���K�����ꂽ�X�N���[�����W���r���[��Ԃ֕ϊ�
	float4 Position = CalucuViewPosFromScreenPos( UV );
	//�@���擾
	float3 Normal = tex2D( NormalSamp, UV ).rgb * 2.0 - 1.0;
	Normal = normalize( Normal );
	//�[�x���擾
	float Depth = tex2D( DepthSamp, UV ).r;

	//if( Depth > 0.997 ) return float4( 1.0, 1.0, 1.0, 1.0 );

	float NormalAO = .0f;
	float DepthAO = .0f;

	//Ray���΂��ĎՕ��̔���
	for( int i = 0; i < NUM_SAMPLES; i++ )
	{
		//Ray
		float3 Ray = SphereArray[i] * HemRadius;

		//Ray��@�������̔������Ɏ��܂�悤�ɕϊ�
		Ray = sign( dot( Normal, Ray ) ) * Ray;

		//���̓s�N�Z���̍��W
		float4 AroundPos = 1;
		AroundPos.xyz = Position.xyz + Ray;
		AroundPos = mul( AroundPos, matProjection );
		//�X�N���[�����W�ɕϊ�
		AroundPos.xy = AroundPos.xy / AroundPos.w * float2( .5, -.5 ) + .5;
		//�@���x�N�g���̎擾
		float3 AroundNormal = tex2D( NormalSamp, AroundPos.xy ).rgb * 2.0 - 1.0;
		AroundNormal = normalize( AroundNormal );
		//�[�x�擾
		float AroundDepth = tex2D( DepthSamp, AroundPos.xy ).r;

		float p = dot( Normal, AroundNormal ) * .5 + .5;

		//�G�b�W���ʂɂȂ��Ă��镔���͎Օ�����Ȃ��悤��
		p += step( Depth, AroundDepth );
		NormalAO += min( p, 1.0f );

		//�[�x���̋����������قǉe�����������Ȃ�
		DepthAO += abs( Depth - AroundDepth ) / Zfar;

	}

	float Color = NormalAO / (float)NUM_SAMPLES + DepthAO;
	Color = pow( Color, AOPower );

	Out.rgb = Color;
	Out.a = 1.0;
	return Out;
}

technique ssao
{
	pass P0
	{
		AlphaBlendEnable = false;
		BlendOp = Add;
		SrcBlend = SrcAlpha;
		DestBlend = InvSrcAlpha;
		CullMode = None;
		ZEnable = false;

		PixelShader  = compile ps_3_0 PS_SSAO();
	}
	pass P1
	{
		AlphaBlendEnable = true;
		BlendOp = Add;
		SrcBlend = SrcAlpha;
		DestBlend = InvSrcAlpha;
		CullMode = None;
		ZEnable = false;

		PixelShader  = compile ps_3_0 PS_Blur();
	}
}