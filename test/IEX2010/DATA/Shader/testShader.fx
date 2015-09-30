//********************************************************************
//																									
//		３Ｄ用シェーダー		
//
//********************************************************************
//------------------------------------------------------
//		環境関連
//------------------------------------------------------
float4x4 Projection;	//	投影変換行列
float4x4 InvProjection;	//	逆投影変換行列
float4x4 TransMatrix;	//	ワールド変換行列
float4x4 matView;		//	カメラ変換行列
float4x4 matProjection;

float3 ViewPos;			//カメラ位置

//-----------------------------------------------------------------------------------------------------------
//		平行光
//-----------------------------------------------------------------------------------------------------------
float3 DirLightVec = { -1, 0, 0 };
float3 DirLightColor = { 1.0f, 1.0f, 1.0f };

//-----------------------------------------------------------------------------------------------------------
//		点光源
//-----------------------------------------------------------------------------------------------------------
float3 pLight_Pos[20];
float3 pLight_Color[20];
float pLight_Range[20];
int pLight_Num= 0;

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

texture HeightMap;		//	高さマップテクスチャ
sampler HeightSamp = sampler_state
{
    Texture = <HeightMap>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = NONE;

    AddressU = Wrap;
    AddressV = Wrap;
};

texture SpecularMap;	//	スペキュラマップテクスチャ
sampler SpecularSamp = sampler_state
{
    Texture = <SpecularMap>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = NONE;

    AddressU = Wrap;
    AddressV = Wrap;
};

textureCUBE CubeMap;	//キューブマップテクスチャ
samplerCUBE CubeSamp = sampler_state
{
	Texture = <CubeMap>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
};

//------------------------------------------------------
//		頂点フォーマット
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
	float4 wPos		: TEXCOORD1;
	float3 Eye		: TEXCOORD2;
	float3 Light	: TEXCOORD3;
	float3 Normal	: TEXCOORD4;
};

float Metalness = 1.0f;
float Roughness = 0.1f;

//********************************************************************
//
//		Unreal Engine参考
//
//*********************************************************************

//円周率
static const float PI = 3.14159265f;

//ディスプレイガンマ値
static const float gamma = 2.2f;

//ネイピア数
static const float E = 2.71828f;

//最大ミップマップレベル
int MaxMipMaplevel = 0;

//半球積分を用いたLambert
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

//マイクロファセットの分布関数
//Beckmann
float Distribution( in const float roughness, in const float NoH )
{
	float alpha = pow( roughness, 2 );
	float alpha2 = pow( alpha, 2 );
	float NoH2 = pow( NoH, 2 );
	//return alpha2 / ( PI * pow( NoH2 * ( alpha - 1 ) + 1, 2 ) );
	return exp( (NoH2 - 1 ) / (alpha2 * NoH2) ) / ( PI * alpha2 * NoH2 * NoH2 );
}

//Fresnel項(Schlickの近似式を利用)
float3 Fresnel( in const float3 SpecularColor, in const float cosT )
{
	//return SpecularColor + ( 1 - F0 ) * pow( E, -6 * cosT );
	float Fc = pow( 1 - cosT, 5 );
	return saturate( 50.0 * SpecularColor.g ) * Fc + SpecularColor * ( 1.0 - Fc );
}

//幾何減衰率
//Smith
float G1( in const float Dot, in const float roughness )
{
	//float k = pow( roughness+1, 2 ) / 8;
	float k = pow( roughness, 2 );
	//return ( Dot * ( 1 - k ) + k );
	return Dot * sqrt((-Dot * k + Dot) * Dot + k );
}

float Geometric( in const float NoL, in const float NoE, in const float roughness )
{
	return 0.5 / ( G1( NoL, roughness ) + G1( NoE, roughness ) );
	//return 1 / ( 4 * max( NoL, NoE ) );
}

//CookTorrance
float CookTorrance( in const float3 N,in const float3 L, in const float3 E, in const float roughness, in const float3 F0 )
{
	//HalfVector
	float3 H = normalize( L + E );
	float NoE = saturate( dot( N, E ) );
	float NoL = saturate( dot( N, L ) );
	float NoH = saturate( dot( N, H ) );
	float LoH = saturate( dot( L, H ) );
	float EoH = saturate( dot( E, H ) );

	//Beckmann項
	float D = Distribution( roughness, NoH );

	//Fresnel項
	float F = Fresnel( F0, EoH );

	//幾何減衰率項
	float Vis = Geometric( NoL, NoE, roughness );

	/*
		D * F * G / 4 * NoL * NoE
		= D * F * Vis
		Vis = G / 4 * NoL * NoE
	*/
	//return ( D * F * G ) / ( 4 * NoL * NoE );
	return ( D * F * Vis ) / PI; 
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

	float3 E = Out.wPos.xyz - ViewPos;
	Out.Eye.x = dot( vx, E );
	Out.Eye.y = dot( vy, E );
	Out.Eye.z = dot( N, E );

	Out.Normal = N;

	return Out;
}

//PixelShader
float4 PS_testPBR( VS_PBR In ) : COLOR0
{
	float4 Out = 1.0;

	float3 L = normalize( In.Light );
	float3 E = normalize( -In.Eye );
	float3 N = tex2D( NormalSamp, In.Tex ).xyz * 2.0f - 1.0f;
	//float3 N = normalize( In.Normal );
	float3 R = reflect( E, N );

	float4 Albedo = tex2D( DecaleSamp, In.Tex );
	Albedo.rgb = pow( Albedo.rgb, gamma );		//ディスプレイガンマを考慮して補正

	//Diffuse
	float3 Diffuse = Albedo.rgb * NormalizeLambert( N, L );		//正規化Lambert
	//float3 Diffuse = OrenNayar( N, L, E, Roughness );	//OrenNaya

	//Specular
	float2 EnvBRDF;
	float3 SpecularColor = lerp( DirLightColor, Albedo.rgb, Metalness );
	float3 Specular = SpecularColor * CookTorrance( N, L, E, Roughness, SpecularColor );

	//PointLight
	/*for (int i = 0; i < pLight_Num; i++)
	{		
		float3 v = In.wPos.xyz - pLight_Pos[i];
		float d = length(v);

		if ( d > pLight_Range[i] ) continue;

		v = normalize( v );
		float insensity = max( 0.0, 1.0 - (d / pLight_Range[i]) );

		Diffuse += pLight_Color[i] * OrenNayar(N, v, E, Roughness) * insensity;
		Specular += pLight_Color[i] * CookTorrance(N, v, E, Roughness, F0) * insensity;
	}*/

	//DiffuseIBL
	float3 DiffuseIBL = Albedo * texCUBEbias( CubeSamp, float4( N, (MaxMipMaplevel+1)/2) ).rgb;

	//SpecularIBL
	//float3 SpecularIBL = texCUBEbias( CubeSamp, float4( R, Roughness*(MaxMipMaplevel+1)) ).rgb * ( SpecularColor * EnvBRDF.x + EnvBRDF.y );
	float3 SpecularIBL = texCUBEbias( CubeSamp, float4( R, Roughness*(MaxMipMaplevel+1)) ).rgb * SpecularColor;

	Out.rgb = lerp( Diffuse, Specular, Metalness );			//直接光
	Out.rgb += lerp( DiffuseIBL, SpecularIBL, Metalness );	//間接光
	//Out.rgb = Specular;

	Out.rgb = pow( Out.rgb, 1.0f/gamma );		//ディスプレイガンマの逆補正をかけて出力(線形空間レンダリング)
	return Out;
}

//********************************************************************
//
//		基本３Ｄシェーダー		
//
//********************************************************************
//------------------------------------------------------
//		頂点シェーダー	
//------------------------------------------------------
VS_OUTPUT VS_Basic( VS_INPUT In )
{
    VS_OUTPUT Out = (VS_OUTPUT)0;

    Out.Pos = mul(In.Pos, Projection);
	Out.Tex = In.Tex;

    return Out;
}

//------------------------------------------------------
//		ピクセルシェーダー	
//------------------------------------------------------

//ガンマ補正なし
float4 PS_Basic( VS_OUTPUT In) : COLOR0
{   
	return tex2D( DecaleSamp, In.Tex );
}

//------------------------------------------------------
//		通常描画テクニック
//------------------------------------------------------
//ガンマ補正なし
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
		PixelShader  = compile ps_3_0 PS_testPBR();
	}
}