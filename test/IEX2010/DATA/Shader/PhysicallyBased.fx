//------------------------------------------------------
//		�e�N�X�`���T���v���[	
//------------------------------------------------------
texture ColorMap;
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
	Texture   = <NormalMap>;
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
	Texture   = <MetalMap>;
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
	BorderColor = float4( .0f, .0f, .0f, 1.0f );
};

texture RoughnessMap;  //  ���t�l�X�}�b�v
sampler RoughnessSamp = sampler_state
{
	Texture   = <RoughnessMap>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = NONE;

	AddressU = Wrap;
	AddressV = Wrap;
};

textureCUBE CubeMap;	//�L���[�u�}�b�v�e�N�X�`��
samplerCUBE CubeSamp = sampler_state
{
	Texture   = <CubeMap>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
};

float testMetalness = 1.0f;  //CPU������l�������Ă��鉼�̕ϐ�
float testRoughness = 0.1f;  //CPU������l�������Ă��鉼�̕ϐ�

texture MRMap;    //Deferred�pMetalness��Roughness���i�[����e�N�X�`��
sampler MRSamp = sampler_state
{
	Texture = <MRMap>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = NONE;

	AddressU = Border;
	AddressV = Border;
	BorderColor = float4( .0f, .0f, .0f, 1.0f );
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

//�t���e�ϊ��s��
float4x4 InvProjection;	

//�~����
static const float PI = 3.14159265f;

//�f�B�X�v���C�K���}�l
static const float gamma = 2.2f;

//�ő�~�b�v�}�b�v���x��
int MaxMipMaplevel = 0;

//���R�ΐ��̒�(�l�C�s�A��)
static const float E = 2.71828f;

//-------------------------------------------------------------------
// @brief �X�N���[�����W����r���[���W�n�̈ʒu���Z�o����
//
// @param ScreenPos   �X�N���[�����W(UV�l)
//
// @return �r���[��Ԃł̍��W��Ԃ�
//-------------------------------------------------------------------
float4 CalucuViewPosFromScreenPos( in float2 UV )
{
	float4 position = (float4)1.0f;

	position.xy = UV * 2.0f - 1.0f;   //-1����1�ɖ߂�
	position.y = -position.y;
	position.z = tex2D( DepthSamp, UV ).r;

	//�t�s����|���ăr���[���W�n�ɕϊ�
	position = mul( position, InvProjection );
	position.xyz /= position.w;

	return position;
}

//********************************************************************
//																									
//		Deferred�pG-Buffer�쐬	
//
//********************************************************************

struct VS_G_BUFFER
{
	float4 Position			: POSITION;
	float2 UV				: TEXCOORD0;
	float3 Normal			: TEXCOORD1;
	float3 BiNormal			: TEXCOORD2;
	float3 Tangent			: TEXCOORD3;
	float4 ProjectionPos	: TEXCOORD4;
};

struct PS_G_BUFFER
{
	float4 Color	: COLOR0;
	float4 Normal	: COLOR1;
	float4 Depth	: COLOR2;
	float4 MR		: COLOR3;	//Metalness,Roughness
};

VS_G_BUFFER VS_CreateG_Buffer( VS_INPUT In )
{
	VS_G_BUFFER Out = (VS_G_BUFFER)0;

	Out.Position      = mul( In.Pos, Projection );
	Out.ProjectionPos = Out.Position;

	Out.UV = In.UV;

	//���_�X�N���[�����W�n�Z�o
	Out.Normal   = mul( In.Normal, (float3x3)TransMatrix );
	Out.Normal   = mul( Out.Normal, (float3x3)matView );
	Out.Normal   = normalize( Out.Normal );
	float3 Y     = { 0, 1, 0.00001 };  //����Y�����x�N�g��
	Out.Tangent  = cross( Y, Out.Normal );
	Out.Tangent  = normalize( Out.Tangent );
	Out.BiNormal = cross( Out.Tangent, Out.Normal );
	Out.BiNormal = normalize( Out.BiNormal );

	return Out;
}

PS_G_BUFFER PS_CreateG_Buffer( VS_G_BUFFER In ) : COLOR
{
	PS_G_BUFFER Out = (PS_G_BUFFER)0;

	Out.Color = tex2D( DecaleSamp, In.UV );
	
	//�@�����r���[���W�n�ɕϊ�
	float3x3 View;
	View[0] = normalize( In.Tangent );
	View[1] = normalize( In.BiNormal );
	View[2] = normalize( In.Normal );
	float3 N = tex2D( NormalSamp, In.UV ).rgb * 2.0 - 1.0;
	N = mul( N, View );
	N = normalize( N );
	N = N * 0.5 + 0.5;
	Out.Normal = float4( N, 1 );
	
	float D = In.ProjectionPos.z / In.ProjectionPos.w;
	//�{���̓e�N�X�`������ǂݍ���
	//float M = tex2D( MetalnessSamp, In.Tex ).r;
	//float R = tex2D( RoughnessSamp, In.Tex ).r;
	float M   = testMetalness;
	float R   = testRoughness;
	Out.Depth = float4( D.rrr, 1 );
	Out.MR    = float4( M, R, 1, 1 );
	
	return Out;
}

technique create_gbuffer
{
	pass P0
	{
		AlphaBlendEnable = true;
		BlendOp          = Add;
		SrcBlend         = SrcAlpha;
		DestBlend        = InvSrcAlpha;
		CullMode         = CCW;
		ZEnable          = true;

		VertexShader = compile vs_3_0 VS_CreateG_Buffer();
		PixelShader  = compile ps_3_0 PS_CreateG_Buffer();
	}
}

//********************************************************************
//																									
//		�����x�[�X�p���C�e�B���OBRDF
//
//********************************************************************

//-------------------------------------------------------------------
//
//		�f�B�t���[�Y��
//
//-------------------------------------------------------------------

//-------------------------------------------------------------------
// @brief �G�l���M�[�ۑ����l������Lambert�̌v�Z
//
// @param Normal   �@��
// @param LightDir �����x�N�g��
//
// @return �f�B�t���[�Y���C�e�B���O���ʂ�Ԃ�
//-------------------------------------------------------------------
float3 NormalizeLambert( in const float3 Normal, in const float3 LightDir )
{
	return max( 0, dot( Normal, LightDir ) ) * ( 1.0f / PI );
}

//-------------------------------------------------------------------
// @brief Oren-Nayar���f���̌v�Z
//
// @param Normal    �@��
// @param LightDir  �����x�N�g��
// @param Eye       �����x�N�g��
// @param Roughness �ʂ̎���(��邩�U���U����)
//
// @return �f�B�t���[�Y���C�e�B���O���ʂ�Ԃ�
//
// @note Roughness�̒l��0.0~1.0����͂���
//-------------------------------------------------------------------
float3 OrenNayar( in const float3 Normal, in const float3 LightDir,
	              in const float3 Eye, in const float Roughness )
{
	float3 N = normalize( Normal );
	float3 L = normalize( LightDir );
	float3 E = normalize( Eye );
	float a = Roughness * Roughness;

	float NoE = dot( N, E );
	float NoL = dot( N, L );
	float A = 1.0f - 0.5f * ( a / ( a + 0.33f ) );
	float B = 0.45 *  a / ( a + 0.09);
	float3 al = normalize( L - NoL * N );
	float3 ae = normalize( E - NoE * N );
	float C = max( 0, dot( al, ae ) );
	float sinT = max( NoL, NoE );
	float tanT = min( NoL, NoE );

	return NoL * ( A + B * C * sinT * tanT ) / PI;
}

//-------------------------------------------------------------------
//
//		�X�y�L������
//
//-------------------------------------------------------------------

//-------------------------------------------------------------------
// @brief Trowbridge-Reitz(GGX)�̌v�Z
//
// @param Roughness �ʂ̎���(��邩�U���U����)
// @param NoH       �@���ƃn�[�t�x�N�g���̓���
//
// @return �}�C�N���t�@�Z�b�g�̕��z�֐�D(h)�̌v�Z���ʂ�Ԃ�
//
// @note Roughness�̒l��0.0~1.0����͂���
//-------------------------------------------------------------------
float3 GGX( in const float Roughness, in const float NoH )
{
	float alpha = pow( Roughness, 2 );
	float alpha2 = pow( alpha, 2 );
	float NoH2 = pow( NoH, 2);
	float D = alpha2 / ( PI * pow( NoH2 * ( alpha - 1 ) + 1, 2 ) );
	return float3( D, D, D );
}

//�}�C�N���t�@�Z�b�g�̕��z�֐��͐F�X����݂����₩��F�X��������

//-------------------------------------------------------------------
// @brief Schlick�̋ߎ����Ńt���l�����˗��̌v�Z
//
// @param F0   �t���l�����˗�
// @param cosT 
//
// @return �t���l�����˗�F(v,h)�̌v�Z���ʂ�Ԃ�
//
//-------------------------------------------------------------------
float3 Fresnel( in const float3 F0, in const float cosT )
{
	return F0 + ( 1 - F0 ) * pow( 1 - cosT, 5 );
}

//�K�E�V�A�����͌��

//-------------------------------------------------------------------
// @brief �􉽌������̊e�����v�Z������(IBL�p)
//
// @param Dot       ����
// @param Roughness �ʂ̎���(��邩�U���U����)
//
// @return �v�Z���ʂ�Ԃ�
//
//-------------------------------------------------------------------
float G1( in const float Dot, in const float Roughness )
{
	float k = pow( Roughness+1, 2 ) / 8;
	return Dot / ( Dot * ( 1 - k ) + k );
}

//-------------------------------------------------------------------
// @brief �􉽌������̊e�����v�Z������(PointLight�p)
//
// @param Dot       ����
// @param Roughness �ʂ̎���(��邩�U���U����)
//
// @return �v�Z���ʂ�Ԃ�
//
// @note �X�y�L���������邭�Ȃ肷���邽�߃}�b�s���O����������
//-------------------------------------------------------------------
float G2( in const float Dot, in const float Roughness )
{
	float roughness = ( 0.5f + Roughness ) / 2.0f; //0~1���ƃX�y�L���������邭�Ȃ肷���邽��0.5~1�Ƀ}�b�s���O
	float k = pow( roughness, 2 ) / 2.0f;
	return Dot / (Dot * (1 - k) + k);
}

//-------------------------------------------------------------------
// @brief �􉽌������̌v�Z(IBL�p)
//
// @param NoL       �@���ƌ����̓���
// @param NoE       �@���Ǝ����̓���
// @param Roughness �ʂ̎���(��邩�U���U����)
//
// @return �􉽊w������G(l,v,h)�̌v�Z���ʂ�Ԃ�
//
// @note Roughness�̒l��0.0~1.0����͂���
// @note 1��IBL�p2�̓|�C���g���C�g�Ƃ��p
//-------------------------------------------------------------------
float3 Geometric1( in const float NoL, in const float NoE, in const float Roughness )
{
	return G1( NoL, Roughness ) * G1( NoE, Roughness );
}

float3 Geometric2( in const float NoL, in const float NoE, in const float Roughness )
{
	return G2(NoL, Roughness) * G2(NoE, Roughness);
}

//-------------------------------------------------------------------
// @brief CookTorrance�̌v�Z( D(h)F(v,h)G(l,v,h) / 4(n�El)(n�Ev) )
//
// @param Normal    �@��
// @param LightDir  �����x�N�g��
// @param Eye       �����x�N�g��
// @param Roughness �ʂ̎���(��邩�U���U����)
// @param F0        �t���l�����˗�
//
// @return �X�y�L�������C�e�B���O�̌��ʂ�Ԃ�
//
// @note Roughness�̒l��0.0~1.0����͂���
//-------------------------------------------------------------------
float3 CookTorrance1( in const float3 Normal, in const float3 LightDir, in const float3 Eye,
	               in const float Roughness, in const float3 F0 )
{
	//HalfVector
	float3 H = normalize( LightDir + Eye );
	float NoE = dot( Normal, Eye );
	float NoL = dot( Normal, LightDir );
	float NoH = dot( Normal, H );
	float LoH = dot( LightDir, H );
	float EoH = dot( Eye, H );

	//�}�C�N���t�@�Z�b�Ƃ̕��z�֐�D(h)
	float3 D = GGX( Roughness, NoH );

	//�t���l�����˗�F(v,h)
	float3 F = Fresnel( F0, LoH );

	//�􉽌�������G(l,v,h)
	float3 G = Geometric1( NoL, NoE, Roughness );

	return ( D * F * G ) / ( 4 * NoL * NoE );
}

float3 CookTorrance2( in const float3 Normal, in const float3 LightDir, in const float3 Eye,
	                  in const float Roughness, in const float3 F0 )
{
	//HalfVector
	float3 H = normalize( LightDir + Eye );
	float NoE = dot( Normal, Eye );
	float NoL = dot( Normal, LightDir );
	float NoH = dot( Normal, H );
	float LoH = dot( LightDir, H );
	float EoH = dot( Eye, H );

	//�}�C�N���t�@�Z�b�Ƃ̕��z�֐�D(h)
	float3 D = GGX( Roughness, NoH );

	//�t���l�����˗�F(v,h)
	float3 F = Fresnel( F0, EoH );

	//�􉽌�������G(l,v,h)
	float3 G = Geometric2( NoL, NoE, Roughness );

	return ( D * F * G ) / ( 4 * NoL * NoE );
}

//********************************************************************
//																									
//		Deferred�pDirLight
//
//********************************************************************

struct PS_DEFERRED
{
	float4 Color    : COLOR0;
	float4 Specular : COLOR1;
	float4 IBL      : COLOR2;
};

float3 LightVec = { 1.0f, -1.0f, 1.0f };
float3 LightColor = { 1.0f, 1.0f, 1.0f };

PS_DEFERRED PS_DirLight( float2 UV : TEXCOORD0 ) : COLOR
{
	PS_DEFERRED Out = ( PS_DEFERRED )0;

    //BaseColor
    float4 BaseColor = tex2D(ColorSamp, UV);
    
    float4 Position = CalucuViewPosFromScreenPos( UV );
	float3 Eye = normalize( -Position.xyz );

	//�����x�N�g�����r���[��ԂŌv�Z
    float3 Light = normalize( mul( -LightVec, (float3x3)matView ) );
    //�@���}�b�v����@���̎擾
    float3 Normal = tex2D( NormalSamp, UV ).xyz * 2.0f - 1.0f;
	Normal = normalize( Normal );
	//���˃x�N�g��
	float3 Reflect = reflect( -Eye, Normal );
	Reflect = normalize( Reflect );

	//�����悤�Ƀ��t�l�X�A���^���l�X���擾
	float Metalness = tex2D( MRSamp, UV ).r;
	float Roughness = tex2D( MRSamp, UV ).g;

	//Diffuse
	float3 Diffuse = LightColor * OrenNayar( Normal, Light, Eye, Roughness ); //OrenNayar
	//float3 Diffuse = LightColor * NormalizeLambert( Normal, Light ); //���K�������o�[�g

	//Specular
	float3 SpecularColor = lerp( float3( 1.0f, 1.0f, 1.0f ), BaseColor.rgb, Metalness );
	float3 Specular = CookTorrance1( Normal, Light, Eye, Roughness, SpecularColor );

	//�o��
	Out.Color.rgb = Diffuse * ( 1.0f - Metalness );  //Specular�Ƃ̑��a���P�𒴂��Ȃ��悤��
	Out.Color.a = 1.0f;

	Out.Specular.rgb = Specular * Metalness;         //Diffuse�Ƃ̑��a���P�𒴂��Ȃ��悤��
	Out.Specular.a = 1.0f;

	Out.IBL = texCUBEbias( CubeSamp, float4( Reflect, Roughness * (MaxMipMaplevel+1) ) );
    
    return Out;
}

technique dirlight
{
	pass P0
	{
		AlphaBlendEnable = true;
		BlendOp = Add;
		SrcBlend = SrcAlpha;
		DestBlend = InvSrcAlpha;
		CullMode = None;
		ZEnable = false;

		PixelShader = compile ps_3_0 PS_DirLight();
	}
}

//********************************************************************
//																									
//		����
//
//********************************************************************

float4 PS_Deferred( float2 UV : TEXCOORD0 ) : COLOR0
{
	float4 Out = (float4)1.0f;

	Out = tex2D( ColorSamp, UV );
	Out.rgb = pow( Out.rgb, gamma );		//�f�B�X�v���C�K���}���l�����ĕ␳

	Out.rgb *= tex2D( LightSamp, UV ).rgb;

	Out.rgb += tex2D( SpecularSamp, UV ).rgb;

	//Out.rgb *= tex2D( IBLSamp, UV ).rgb;

	Out.rgb = pow( Out.rgb, 1.0f / gamma ); //�f�B�X�v���C�K���}�̋t�␳�������ďo��
	return Out;
}

technique deferred
{
	pass P0
	{
		AlphaBlendEnable = true;
		BlendOp = Add;
		SrcBlend = SrcAlpha;
		DestBlend = InvSrcAlpha;
		CullMode = None;
		ZEnable = false;

		PixelShader = compile ps_3_0 PS_Deferred();
	}
}