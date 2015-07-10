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

struct VS_CUBE
{
	float4 Pos		: POSITION;
	float2 Tex		: TEXCOORD0;
	float3 Normal	: TEXCOORD1;
	float3 Eye		: TEXCOORD2;
	float3 wPos		: TEXCOORD3;
};

struct VS_PBR
{
	float4 Pos		: POSITION;
	float2 Tex		: TEXCOORD0;
	float3 wPos		: TEXCOORD1;
	float3 Normal	: TEXCOORD2;
	float3 Eye		: TEXCOORD3;
};

float Metalness = 1.0f;
float Roughness = 0.1f;

//********************************************************************
//
//		GGX��p�����X�y�L�����v�Z		
//
//********************************************************************
static const float PI = 3.14159265f;
static const float OneDivPI = 1 / PI;

float G1V( float dotNV, float k )
{
	return 1.0f / (dotNV * (1.0f - k) + k);
}

float GGX_PhongCalculate( float3 Normal, float3 Eye, float3 Light, float roughness,
						  float F0 /* �t���l�����˗� */)
{
	float alpha = roughness * roughness;

	//�n�[�t�x�N�g��
	float3 H = normalize(Eye + Light);

	float NL = saturate(dot(Normal, Light));
	float NE = saturate(dot(Normal, Eye));
	float NH = saturate(dot(Normal, H));
	float LH = saturate(dot(Light, H));

	//GGX��NDF
	float alphaSqr = alpha * alpha;
	float denom = NH * NH * (alphaSqr - 1.0f) + 1.0f;
	float Distribution = alphaSqr / (PI * denom * denom);

	//�t���l���̃V�����b�N�ߎ�
	float Fresnel = F0 + (1.0f - F0) * pow(1.0f - LH, 5);

	//
	float k = alpha / 2.0f;
	float vis = G1V( NL, k ) * G1V( NE, k );

	return NL * Distribution * Fresnel * vis;
}

//********************************************************************
//
//
//
//*********************************************************************

static const float k0 = 0.00098, k1 = 0.9921, fUserMaxSPow = 0.2425;
static const float g_fMaxT = ( exp2( -10.0f/sqrt(fUserMaxSPow)) - k0 ) / k1;
static const int nMipOffset = 0;

float GetSpecPowToMip( float fSpecPow, int nMips )
{
	fSpecPow = 1 - pow( 1 - fSpecPow, 8 );
	float fSmulMaxT = ( exp2( -10.0f / sqrt( fSpecPow ) ) - k0 ) / k1;
	return float( nMips-1-nMipOffset) * ( 1.0 - clamp( fSmulMaxT / g_fMaxT, 0.0, 1.0 ));
}

float3x3 contangent_frame( float3 N, float3 p, float2 Tex )
{
	float3 dp1 = ddx(p);
	float3 dp2 = ddy(p);
	float2 duv1 = ddx(Tex);
	float2 duv2 = ddy(Tex);

	float3 dp2perp = cross( dp2, N );
	float3 dp1perp = cross( N, dp1 );
	float3 T = dp2perp * duv1.x + dp1perp * duv2.x;
	float3 B = dp2perp * duv1.y + dp1perp * duv2.y;

	float invmax = rsqrt( max( dot( T,T), dot(B,B)) );
	return float3x3( T*invmax, B*invmax, N );

}

float3 pertub_normal( float3 N, float3 V, float2 Tex)
{
	float3 map = tex2D( NormalSamp, Tex ).xyz;
	map = map * 2.0 - 1.0;

	float3x3 TBN = contangent_frame( N, -V, Tex );
	return normalize( mul( map, TBN ) );
}

VS_PBR VS_testPBR( VS_INPUT In )
{
	VS_PBR Out = (VS_PBR)0;
	Out.Pos = mul( In.Pos, Projection );
	Out.Tex = In.Tex;
	Out.Normal = mul( In.Normal, (float3x3)TransMatrix );
	Out.wPos = mul( In.Pos, TransMatrix );
	Out.Eye = Out.wPos - ViewPos;
	return Out;
}

float4 PS_testPBR( VS_PBR In ) : COLOR0
{
	float4 Out = 0;

	float3 L = normalize( DirLightVec );
	float3 E = normalize( In.Eye );
	float3 N = normalize( In.Normal );
	float3x3 TBN = contangent_frame( N, E, In.Tex );
	N = normalize( mul( N, TBN ) );
	float3 camNormalReflect = normalize( reflect( E, N ) );

	//Sample texture
	float4 Albedo = tex2D( DecaleSamp, In.Tex );
	//metalness�ɂ����specular�J���[��albedo�J���[�̌���
	float4 specularColor = float4(lerp(0.04f.rrr, Albedo.rgb, Metalness ), 1.0f );
	Albedo.rgb = lerp( Albedo.rgb, 0.0f.rrr, Metalness );
	Albedo = pow( Albedo, 2.2 );

	//Diffuse
	float4 Diffuse = float4((saturate( dot(-L, N))*OneDivPI) * DirLightColor * Albedo.rgb, 1.0);
	Diffuse.rgb += Albedo.rgb;
	
	float3 H = normalize( E + L );
	float HoN = saturate( dot( H, N ) );
	float NoL = saturate( dot( N, -L ) );
	float NoE = saturate( dot( N, -E ) );

	float alpha = Roughness * Roughness;
	float alphaSq = alpha * alpha;
	float alphaHalf = alpha * 0.5;

	//Fresnel
	float4 schlicFresnel = specularColor + (1-specularColor) * (pow(1-dot(L,E), 5) / ( 6-5*(1-Roughness)));

	float denominator = HoN * HoN * ( alphaSq - 1 ) + 1;
	float ggxDistribution = alphaSq / ( PI * denominator * denominator );
	float ggxGeometry = ( NoE / ( NoE * ( 1 - alphaHalf ) + alphaHalf ) );

	//Specular
	float4 Specular = float4(((schlicFresnel*ggxDistribution*ggxGeometry) / 4*NoL*NoE).rrr * DirLightColor * specularColor.rgb, 1.0);
	//SpecularIBL
	int mipLevels = 10;
	float4 SpecularIBL = texCUBElod(CubeSamp, float4(camNormalReflect, GetSpecPowToMip(Roughness,mipLevels) ) );
	SpecularIBL = pow( SpecularIBL, 2.2 );
	NoE = saturate( dot( lerp( In.Normal, N, saturate( dot( In.Normal, -E) )), -E) );
	float4 Fresnel = saturate( specularColor + (1-specularColor)*pow(1-NoE, 5));

	Out = lerp( Diffuse, SpecularIBL, Fresnel );
	Out += Specular;

	Out = pow( abs( Out ), 1.0/2.2 );
	Out.a = 1.0;

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
	Out.Color = 1.0f;
	Out.Normal = mul( In.Normal, (float3x3)TransMatrix );
	Out.Normal = normalize( Out.Normal );
	Out.wPos = mul( In.Pos, TransMatrix );

    return Out;
}

//------------------------------------------------------
//		�L���[�u�}�b�v�p���_�V�F�[�_�[	
//------------------------------------------------------
VS_CUBE VS_Cube( VS_INPUT In )
{
	VS_CUBE Out = (VS_CUBE)0;

	Out.Pos = mul( In.Pos, Projection );
	Out.Tex = In.Tex;
	Out.Normal = normalize( mul( In.Normal, (float3x3)TransMatrix ) );
	Out.wPos = mul( In.Pos, TransMatrix );
	Out.Eye = normalize( Out.wPos - ViewPos );

	return Out;
}

//------------------------------------------------------
//		�s�N�Z���V�F�[�_�[	
//------------------------------------------------------

int sppower = 50;

float gamma = 2.2f;

//�K���}�␳�Ȃ�
float4 PS_Basic( VS_OUTPUT In) : COLOR0
{   
	float4	Out;
	//	�s�N�Z���F����
	Out = In.Color * tex2D( DecaleSamp, In.Tex );

	//Lambert
	float3 L = normalize( In.wPos - DirLightVec );
	Out.rgb *= dot( In.Normal, -L ) * 0.5f + 0.5;

	//Phong
	float3 V = normalize( ViewPos - In.wPos );
	float3 R = -V + ( 2.0f * dot( In.Normal, V ) * In.Normal );
	Out.rgb += pow( max( dot( -L, R ), .0f), sppower )  * tex2D( SpecularSamp, In.Tex );

	return Out;
}
//�K���}�␳����
float4 PS_Test( VS_OUTPUT In) : COLOR0
{   
	float4	Out;
	//	�s�N�Z���F����
	Out = In.Color * tex2D( DecaleSamp, In.Tex );
	//�f�B�X�v���C�̃K���}�l���l�����ĕ␳
	//�␳�l��Windows�͖�2.2�AMac�͖�1.8
	Out.rgb = pow(Out.rgb, gamma);

	//���K��Lambert
	float3 L = normalize( In.wPos - DirLightVec );
	Out.rgb *= ( dot( In.Normal, -L ) * 0.5f + 0.5f ) / PI;

	//���K��Phong
	float3 V = normalize(ViewPos - In.wPos);
	//float3 R = -V + (2.0f * dot(In.Normal, V) * In.Normal);
	//Out.rgb += pow(max(dot(-L, R), .0f), sppower) * ((sppower + 1.0f) / (2.0f * PI)) * tex2D(SpecularSamp, In.Tex) * Roughness;
	float specular = GGX_PhongCalculate(In.Normal, V, -L, Roughness, Metalness);
	Out.rgb += specular;

	//�t�␳�������ďo��
	Out.rgb = pow( Out.rgb, 1.0f/2.2f );
	return Out;
}

//------------------------------------------------------
//		�L���[�u�}�b�v�p�s�N�Z���V�F�[�_�[	
//------------------------------------------------------
float4 PS_Cube1( VS_CUBE In ) : COLOR0
{
	float4	Out;
	//	�s�N�Z���F����
	Out = tex2D( DecaleSamp, In.Tex );

	//�L���[�u�}�b�v
	float3 EyeR = normalize( reflect( In.Eye, In.Normal ) );
	//Out.rgb = ( 1.0f - Metalness ) * Out.rgb + Metalness * float3( .0f, .0f, .0f );
	Out.rgb += Metalness * texCUBE( CubeSamp, EyeR ).rgb;

	//Lambert
	float3 L = normalize( In.wPos - DirLightVec );
	Out.rgb *= dot( In.Normal, -L ) * 0.5f + 0.5;

	//Phong
	float3 V = normalize( ViewPos - In.wPos );
	float3 R = -V + ( 2.0f * dot( In.Normal, V ) * In.Normal );
	Out.rgb += pow( max( dot( -L, R ), .0f), sppower )  * tex2D( SpecularSamp, In.Tex ) * Roughness;

	return Out;
}

float4 PS_Cube2( VS_CUBE In ) : COLOR0
{
	float4	Out = float4( .0f, .0f, .0f, 1.0f);
	//	�s�N�Z���F����
	float4 Albedo = tex2D( DecaleSamp, In.Tex );
	Albedo.rgb = pow(Albedo.rgb, gamma);

	//�L���[�u�}�b�v
	float3 EyeR = normalize( reflect( In.Eye, In.Normal ) );
	float3 IBL = texCUBE( CubeSamp, EyeR ).rgb;

	//���K��Lambert
	float3 L = normalize( In.wPos - DirLightVec );
	Albedo.rgb *= ( dot( In.Normal, -L ) * 0.5f + 0.5f ) / PI;

	//���K��Phong
	float3 V = normalize(ViewPos - In.wPos);
	float specular = GGX_PhongCalculate(In.Normal, V, -L, Roughness, Roughness);

	float3 spcolor = Albedo.rgb * Metalness + float3( 1.0f, 1.0f, 1.0f ) * (1.0f - Metalness);
	Out.rgb = Albedo.rgb +IBL * ( 1.0f - Roughness );
	Out.rgb += specular * spcolor;
	Out.rgb = pow( Out.rgb, 1.0f/2.2f );
	return Out;
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

//�K���}�␳����
technique test
{
    pass P0
    {
		AlphaBlendEnable = true;
		BlendOp          = Add;
		SrcBlend         = SrcAlpha;
		DestBlend        = InvSrcAlpha;
		CullMode         = CCW;
		ZEnable          = true;

		VertexShader = compile vs_3_0 VS_Basic();
		PixelShader  = compile ps_3_0 PS_Test();
    }
}

//------------------------------------------------------
//		�L���[�u�}�b�v
//------------------------------------------------------

//�K���}�␳�Ȃ�
technique cube_base
{
    pass P0
    {
		AlphaBlendEnable = true;
		BlendOp          = Add;
		SrcBlend         = SrcAlpha;
		DestBlend        = InvSrcAlpha;
		CullMode         = CCW;
		ZEnable          = true;

		VertexShader = compile vs_2_0 VS_Cube();
		PixelShader  = compile ps_2_0 PS_Cube1();
    }
}

//�K���}�␳����
technique cube_test
{
    pass P0
    {
		AlphaBlendEnable = true;
		BlendOp          = Add;
		SrcBlend         = SrcAlpha;
		DestBlend        = InvSrcAlpha;
		CullMode         = CCW;
		ZEnable          = true;

		VertexShader = compile vs_3_0 VS_Cube();
		PixelShader  = compile ps_3_0 PS_Cube2();
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