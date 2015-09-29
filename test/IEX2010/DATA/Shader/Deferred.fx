//------------------------------------------------------
//		環境関連
//------------------------------------------------------
float4x4 Projection;	//	投影変換行列
float4x4 InvProjection;	//	逆投影変換行列
float4x4 TransMatrix;	//	ワールド変換行列
float4x4 matView;		//	カメラ変換行列
float4x4 matProjection;

struct VS_INPUT
{
    float4 Pos    : POSITION;
    float3 Normal : NORMAL;
    float2 Tex	  : TEXCOORD0;
};

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

float Metalness = 1.0f;
float Roughness = 0.1f;

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

//********************************************************************
//																									
//		Deferred用G-Buffer作成	
//
//********************************************************************

struct VS_G_BUFFER
{
	float4 Position			: POSITION;
	float2 Tex				: TEXCOORD0;
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
	float4 MR		: COLOR3;	//Metalness,Roughenss
};

VS_G_BUFFER VS_CreateG_Buffer( VS_INPUT In )
{
	VS_G_BUFFER Out = (VS_G_BUFFER)0;

	Out.Position = mul( In.Pos, Projection );
	Out.ProjectionPos = Out.Position;
	Out.Tex = In.Tex;
	Out.Normal = mul( In.Normal, (float3x3)TransMatrix );
	Out.Normal = mul( Out.Normal, (float3x3)matView );
	Out.Normal = normalize( Out.Normal );
	float3 Y = { 0, 1, 0.00001 };
	Out.Tangent = cross( Y, Out.Normal );
	Out.Tangent = normalize( Out.Tangent );
	Out.BiNormal = cross( Out.Tangent, Out.Normal );
	Out.BiNormal = normalize( Out.BiNormal );

	return Out;
}

PS_G_BUFFER PS_CreateG_Buffer( VS_G_BUFFER In ) : COLOR
{
	PS_G_BUFFER Out = (PS_G_BUFFER)0;

	Out.Color = tex2D( DecaleSamp, In.Tex );

	float3x3 View;
	View[0] = normalize( In.Tangent );
	View[1] = normalize( In.BiNormal );
	View[2] = normalize( In.Normal );
	float3 N = tex2D( NormalSamp, In.Tex ).rgb * 2.0 - 1.0;
	N = mul( N, View );
	N = normalize( N );
	N = N * 0.5 + 0.5;
	Out.Normal =float4( N, 1 );

	float D = In.ProjectionPos.z / In.ProjectionPos.w;
	//float M = tex2D( MetalnessSamp, In.Tex ).r;
	//float R = tex2D( RoughnessSamp, In.Tex ).r;
	float M = Metalness;
	float R = Roughness;
	Out.Depth = float4( D.rrr, 1 );
	Out.MR = float4( M, R, 1, 1 );

	return Out;
}

technique create_gbuffer
{
	pass P0
	{
		AlphaBlendEnable = true;
		BlendOp = Add;
		SrcBlend = SrcAlpha;
		DestBlend = InvSrcAlpha;
		CullMode = CCW;
		ZEnable = true;

		VertexShader = compile vs_3_0 VS_CreateG_Buffer();
		PixelShader  = compile ps_3_0 PS_CreateG_Buffer();
	}
}

//********************************************************************
//																									
//		DeferredLighting
//
//********************************************************************

texture ColorMap;
sampler ColorSamp = sampler_state
{
	Texture = <ColorMap>;
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

	AddressU = Wrap;
	AddressV = Wrap;
};

texture MRMap;	// M:Metalness, R:Roguhness
sampler MRSamp = sampler_state
{
	Texture = <MRMap>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = NONE;

	AddressU = Wrap;
	AddressV = Wrap;
};

struct VS_2D
{
	float4 Position	: POSITION;
	float2 Tex		: TEXCOORD0;
};

struct PS_Deferred
{
	float4 Screen	: COLOR0;
	float4 Specular	: COLOR1;
};

float4 ConvertViewPosition( in float2 Tex )
{
	float4 screen = 1;
	screen.xy = Tex * 2.0 - 1.0;
	screen.y = -screen.y;
	screen.z = tex2D(DepthSamp, Tex).r;
	float4 position = mul( screen, InvProjection );
	position.xyz /= position.w;
	return position;
}

VS_2D VS_Deferred( VS_INPUT In )
{
	VS_2D Out = (VS_2D)0;
	Out.Position = In.Pos;
	Out.Tex = In.Tex;
	return Out;
}

float3 DirLightVec;
float3 DirLightColor;

PS_Deferred PS_DeferredDirLight( VS_2D In ) : COLOR
{
	PS_Deferred Out = (PS_Deferred)1;

	float D = tex2D( DepthSamp, In.Tex ).r;
	//if( D < 0.00001 ) return tex2D( ColorSamp,In.Tex );

	float4 Albedo = tex2D( ColorSamp, In.Tex );
	Albedo = pow( Albedo, gamma );

	//正規化されたスクリーン座標をビュー空間へ変換
	float4 position = ConvertViewPosition( In.Tex );
	float3 E = normalize( position.xyz );
	float3 DirLight = mul( DirLightVec, (float3x3)matView );
	float3 L = normalize( position.xyz - DirLight );
	float3 N = tex2D( NormalSamp, In.Tex ).rgb * 2.0 - 1.0;
	N = normalize( N );
	float3 Ref = reflect( E, N );
	//float3 Ref = normalize( E + 2 * dot( -E, N ) * N );

	float M = saturate( tex2D( MRSamp, In.Tex ).r );
	float R = saturate( tex2D( MRSamp, In.Tex ).g );

	//Diffuse
	//float3 Diffuse = DirLightColor * NormalizeLambert( N, L );		//正規化Lambert
	float3 Diffuse = Albedo * DirLightColor * OrenNayar( N, L, E, R );	//OrenNaya

	//Specular
	float F0 = M;
	float3 SpecularColor = lerp( float3(1, 1, 1), Albedo, M );
	float3 Specular = SpecularColor * CookTorrance( N, L, E, R, SpecularColor );

	//DiffuseIBL
	float3 DiffuseIBL = texCUBEbias( CubeSamp, float4(N, (MaxMipMaplevel + 1) / 2) ).rgb;

	//SpecularIBL
	//float3 SpecularIBL = texCUBEbias( CubeSamp, float4( Ref, R*(MaxMipMaplevel+1)) ).rgb * ( SpecularColor * EnvBRDF.x + EnvBRDF.y );
	float3 SpecularIBL = texCUBEbias(CubeSamp, float4( Ref, R*(MaxMipMaplevel + 1)) ).rgb * SpecularColor;

	Out.Screen.rgb = Diffuse * ( 1.0 - M ) + DiffuseIBL * ( 1.0 - M );
	Out.Specular.rgb = Specular * M + SpecularIBL * M;
	//Out.rgb += DiffuseIBL + SpecularIBL;

	Out.Screen.rgb = pow( Out.Screen.rgb, 1.0f/gamma );
	return Out;
}

technique Deferred
{
	pass P0
	{
		AlphaBlendEnable = true;
		BlendOp = Add;
		SrcBlend = SrcAlpha;
		DestBlend = One;
		CullMode = None;
		ZEnable = false;

		VertexShader = compile vs_3_0 VS_Deferred();
		PixelShader  = compile ps_3_0 PS_DeferredDirLight();
	}
}