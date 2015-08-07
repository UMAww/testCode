//********************************************************************
//																									
//		�R�c�p�V�F�[�_�[		
//
//********************************************************************
//------------------------------------------------------
//		���֘A
//------------------------------------------------------
float4x4 Projection;	//	���e�ϊ��s��
float4x4 TransMatrix;	//���[���h�ϊ��s��

float3 ViewPos;			//�J�����ʒu

//-----------------------------------------------------------------------------------------------------------
//		���s��
//-----------------------------------------------------------------------------------------------------------
float3 DirLightVec = { -1, 0, 0 };
float3 DirLightColor = { 1.0f, 1.0f, 1.0f };

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

texture HeightMap;		//	�����}�b�v�e�N�X�`��
sampler HeightSamp = sampler_state
{
    Texture = <HeightMap>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = NONE;

    AddressU = Wrap;
    AddressV = Wrap;
};

texture SpecularMap;	//	�X�y�L�����}�b�v�e�N�X�`��
sampler SpecularSamp = sampler_state
{
    Texture = <SpecularMap>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = NONE;

    AddressU = Wrap;
    AddressV = Wrap;
};

textureCUBE CubeMap;	//�L���[�u�}�b�v�e�N�X�`��
samplerCUBE CubeSamp = sampler_state
{
	Texture = <CubeMap>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
};

//------------------------------------------------------
//		���_�t�H�[�}�b�g
//------------------------------------------------------
struct VS_OUTPUT
{
    float4 Pos		: POSITION;
    float4 Color	: COLOR0;
    float2 Tex		: TEXCOORD0;
	float3 Normal	: TEXCOORD1;
	float3 wPos		: TEXCOORD2;
};

struct VS_INPUT
{
    float4 Pos    : POSITION;
    float3 Normal : NORMAL;
    float2 Tex	  : TEXCOORD0;
};

struct VS_PBR
{
	float4 Pos		: POSITION;
	float2 Tex		: TEXCOORD0;
	float3 wPos		: TEXCOORD1;
	float3 Eye		: TEXCOORD2;
	float3 Light	: TEXCOORD3;
};

float Metalness = 1.0f;
float Roughness = 0.1f;

//********************************************************************
//
//
//
//*********************************************************************

//�~����
static const float PI = 3.14159265f;

//�f�B�X�v���C�K���}�l
static const float gamma = 2.2f;

//�l�C�s�A��
static const float E = 2.71828f;

//�ő�~�b�v�}�b�v���x��
int MaxMipMaplevel = 0;

//�����ϕ���p����Lambert
float3 NormalizeLambert( in const float3 N, in const float3 E )
{
	return max( 0, dot( N, E ) ) * ( 1.0f / PI );
}

//Oren-Nayar
float3 OrenNayar( in const float3 N, in const float3 L, in const float3 E, in const float roughness )
{
	float a = roughness * roughness;
	float NoE = saturate( dot( N, E ) );
	float NoL = saturate( dot( N, L ) );
	float A = 1.0 - 0.5 * ( a / (a+0.33) );
	float B = 0.45 *  a / ( a + 0.09 );
	float3 al = normalize( L - NoL * N );
	float3 ae = normalize( E - NoE * N );
	float C = max( 0, dot( al, ae ) );
	float sinT = max( NoL, NoE );
	float tanT = min( NoL, NoE );

	return NoL * ( A + B * C * sinT * tanT ) / PI;
}

//�}�C�N���t�@�Z�b�g�̕��z�֐�
float Distribution( in const float roughness, in const float NoH )
{
	float alpha = pow( roughness, 2 );
	float alpha2 = pow( alpha, 2 );
	float NoH2 = pow( NoH, 2 );
	return alpha2 / ( PI * pow( NoH2 * ( alpha2 - 1 ) + 1, 2 ) );
}

//Fresnel��(Schlick�̋ߎ����𗘗p)
//F0:�t���l�����˗�
float Fresnel( in const float F0, in const float cosT )
{
	return F0 + ( 1 - F0 ) * pow( E, -6 * cosT );
}

//�􉽊w������
float G1( in const float Dot, in const float roughness )
{
	float k = pow( roughness, 2 ) / 2;
	return 1.0f / ( Dot * ( 1 - k ) + k );
}

float Geometric( in const float NoL, in const float NoE, in const float roughness )
{
	return G1( NoL, roughness ) * G1( NoE, roughness );
}

//CookTorrance
float CookTorrance( in const float3 N,in const float3 L, in const float3 E, in const float roughness, in const float F0, out float2 EnvBRDF  )
{
	//HalfVector
	float3 H = normalize( L + E );
	float NoE = saturate( dot( N, E ) );
	float NoL = saturate( dot( N, L ) );
	float NoH = saturate( dot( N, H ) );
	float LoH = saturate( dot( L, H ) );
	float EoH = saturate( dot( E, H ) );

	//Beckmann��
	float D = Distribution( roughness, NoH );

	//Fresnel��
	float F = Fresnel( F0, LoH );

	//�􉽊w��
	float G = Geometric( NoL, NoE, roughness );

	//EnvBRDF
	float G_Vis = G * EoH / ( NoH * NoE );
	float fc = pow( 1 - EoH, 5 );
	EnvBRDF = float2( ( 1 - fc ) * G_Vis, fc * G_Vis );

	return NoL * D * F * G;
}

//VertexShader
VS_PBR VS_testPBR( VS_INPUT In )
{
	VS_PBR Out = (VS_PBR)0;
	Out.Pos = mul( In.Pos, Projection );
	Out.Tex = In.Tex;
	Out.wPos = mul( In.Pos, TransMatrix );

	float3 N = mul( In.Normal, (float3x3)TransMatrix );
	N = normalize( N );
	float3 vx;
	float3 vy = { 0, 1, 0.001 };
	vx = cross( vy, N );
	vx = normalize( vx );
	vy = cross( vx, N );
	vy = normalize( vy );

	Out.Light.x = dot( vx, -DirLightVec );
	Out.Light.y = dot( vy, -DirLightVec );
	Out.Light.z = dot( N, -DirLightVec );

	float3 E = Out.wPos - ViewPos;
	Out.Eye.x = dot( vx, E );
	Out.Eye.y = dot( vy, E );
	Out.Eye.z = dot( N, E );

	return Out;
}

//PixelShader
float4 PS_testPBR( VS_PBR In ) : COLOR0
{
	float4 Out = 1.0;

	float3 L = normalize( In.Light );
	float3 E = normalize( -In.Eye );
	float3 N = tex2D( NormalSamp, In.Tex ).xyz * 2.0f - 1.0f;
	float3 R = reflect( E, N );

	float4 Albedo = tex2D( DecaleSamp, In.Tex );
	Albedo.rgb = pow( Albedo.rgb, gamma );		//�f�B�X�v���C�K���}���l�����ĕ␳

	//Diffuse
	//float3 Diffuse = DirLightColor * NormalizeLambert( N, L );		//���K��Lambert
	float3 Diffuse = Albedo * DirLightColor * OrenNayar( N, L, E, Roughness );	//OrenNaya

	//Specular
	float2 EnvBRDF;
	float F0 = Metalness;
	float3 SpecularColor = lerp( float3( 1, 1, 1 ), Albedo, Metalness );
	float3 Specular = SpecularColor * CookTorrance( N, L, E, Roughness, F0, EnvBRDF );

	//DiffuseIBL
	float3 DiffuseIBL = Albedo * DirLightColor * texCUBEbias( CubeSamp, float4( N, (MaxMipMaplevel+1)/2) ).rgb;

	//SpecularIBL
	//float3 SpecularIBL = texCUBEbias( CubeSamp, float4( R, Roughness*(MaxMipMaplevel+1)) ).rgb * ( SpecularColor * EnvBRDF.x + EnvBRDF.y );
	float3 SpecularIBL = texCUBEbias( CubeSamp, float4( R, Roughness*(MaxMipMaplevel+1)) ).rgb * SpecularColor;

	Out.rgb = lerp( Diffuse, Specular, Metalness );			//���ڌ�
	Out.rgb += lerp( DiffuseIBL, SpecularIBL, Metalness );	//�Ԑڌ�
	//Out.rgb += DiffuseIBL + SpecularIBL;

	Out.rgb = pow( Out.rgb, 1.0f/gamma );		//�f�B�X�v���C�K���}�̋t�␳�������ďo��
	return Out;
}

//********************************************************************
//
//		��{�R�c�V�F�[�_�[		
//
//********************************************************************
//------------------------------------------------------
//		���_�V�F�[�_�[	
//------------------------------------------------------
VS_OUTPUT VS_Basic( VS_INPUT In )
{
    VS_OUTPUT Out = (VS_OUTPUT)0;

    Out.Pos = mul(In.Pos, Projection);
	Out.Tex = In.Tex;

    return Out;
}

//------------------------------------------------------
//		�s�N�Z���V�F�[�_�[	
//------------------------------------------------------

//�K���}�␳�Ȃ�
float4 PS_Basic( VS_OUTPUT In) : COLOR0
{   
	return tex2D( DecaleSamp, In.Tex );
}

//------------------------------------------------------
//		�ʏ�`��e�N�j�b�N
//------------------------------------------------------
//�K���}�␳�Ȃ�
technique base
{
    pass P0
    {
		AlphaBlendEnable = true;
		BlendOp          = Add;
		SrcBlend         = SrcAlpha;
		DestBlend        = InvSrcAlpha;
		CullMode         = CCW;
		ZEnable          = true;

		VertexShader = compile vs_2_0 VS_Basic();
		PixelShader  = compile ps_2_0 PS_Basic();
    }
}

technique pbr_test
{
	pass P0
	{
		AlphaBlendEnable = true;
		BlendOp = Add;
		SrcBlend = SrcAlpha;
		DestBlend = InvSrcAlpha;
		CullMode = CCW;
		ZEnable = true;

		VertexShader = compile vs_3_0 VS_testPBR();
		PixelShader = compile ps_3_0 PS_testPBR();
	}
}