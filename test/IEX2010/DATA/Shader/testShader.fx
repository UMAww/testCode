//********************************************************************
//																									
//		３Ｄ用シェーダー		
//
//********************************************************************
//------------------------------------------------------
//		環境関連
//------------------------------------------------------
float4x4 Projection;	//	投影変換行列
float4x4 TransMatrix;	//ワールド変換行列

float3 ViewPos;			//カメラ位置

//-----------------------------------------------------------------------------------------------------------
//		平行光
//-----------------------------------------------------------------------------------------------------------
float3 DirLightVec = { -1, 0, 0 };
float3 DirLightColor = { 1.0f, 1.0f, 1.0f };

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
//
//
//*********************************************************************

//円周率
static const float PI = 3.14159265f;

//ディスプレイガンマ値
static const float gamma = 2.2f;

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
float Distribution( in const float roughness, in const float NoH )
{
	float alpha = pow( roughness, 2 );
	float alpha2 = pow( alpha, 2 );
	float NoH2 = pow( NoH, 2 );
	return alpha2 / ( PI * pow( NoH2 * ( alpha2 - 1 ) + 1, 2 ) );
}

//Fresnel項(Schlickの近似式を利用)
float3 Fresnel( in const float3 F0, in const float cosT )
{
	return F0 + ( 1 - F0 ) * pow( 1-cosT, 5 );
}

//幾何学減衰率
float G1( in const float Dot, in const float roughness )
{
	float k = pow( roughness, 2 ) / 2;
	return 1.0 / ( Dot * ( 1 - k ) + k );
}

float Geometric( in const float NoL, in const float NoE, in const float roughness )
{
	return G1( NoL, roughness ) * G1( NoE, roughness );
}

//CookTorrance
float3 CookTorrance( in const float3 N,in const float3 L, in const float3 E, in const float roughness, in const float3 F0 )
{
	//HalfVector
	float3 H = normalize( L + E );
	float NoE = saturate( dot( N, E ) );
	float NoL = saturate( dot( N, L ) );
	float NoH = saturate( dot( N, H ) );

	//Beckmann項
	float D = Distribution( roughness, NoH );

	//Fresnel項
	float3 F = Fresnel( F0, dot( L, H ) );

	//幾何学項
	float G = Geometric( NoL, NoE, roughness );

	return ( D * F * G ) / ( 4 * NoL * NoE );
}

//VertexShader
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

//PixelShader
float4 PS_testPBR( VS_PBR In ) : COLOR0
{
	float4 Out = 1.0;

	float3 L = normalize( DirLightVec );
	float3 E = normalize( In.Eye );
	float3 N = normalize( In.Normal );
	//float3 camNormalReflect = normalize( reflect( E, N ) );

	float4 Albedo = tex2D( DecaleSamp, In.Tex );
	Albedo.rgb = pow( Albedo.rgb, gamma );		//ディスプレイガンマを考慮して補正
	Albedo.rgb = Albedo.rgb - Albedo.rgb * (1-Metalness);

	//Diffuse
	//float3 Diffuse = DirLightColor * NormalizeLambert( N, L );		//正規化Lambert
	float3 Diffuse = DirLightColor * OrenNayar( N, L, E, Roughness );	//OrenNaya

	//Specular
	float ior = 1;
	float3 F0 = abs( ( 1.0 - ior ) / ( 1.0 + ior ) );
	F0 = pow( F0, 2 );
	F0 = lerp( F0, Albedo.rgb, Metalness );
	float3 Specular = CookTorrance( N, -L, E, Roughness, F0 );

	//Lighting
	Out.rgb = Albedo.rgb * ( Diffuse + Specular );
	Out.rgb = saturate( Out.rgb );

	Out.rgb = pow( Out.rgb, 1.0f/gamma );		//ディスプレイガンマの逆補正をかけて出力
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
	Out.Color = 1.0f;
	Out.Normal = mul( In.Normal, (float3x3)TransMatrix );
	Out.Normal = normalize( Out.Normal );
	Out.wPos = mul( In.Pos, TransMatrix );

    return Out;
}

//------------------------------------------------------
//		キューブマップ用頂点シェーダー	
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
//		ピクセルシェーダー	
//------------------------------------------------------

int sppower = 50;

//ガンマ補正なし
float4 PS_Basic( VS_OUTPUT In) : COLOR0
{   
	float4	Out;
	//	ピクセル色決定
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
//ガンマ補正あり
float4 PS_Test( VS_OUTPUT In) : COLOR0
{   
	float4	Out;
	//	ピクセル色決定
	Out = In.Color * tex2D( DecaleSamp, In.Tex );
	//ディスプレイのガンマ値を考慮して補正
	//補正値はWindowsは約2.2、Macは約1.8
	Out.rgb = pow(Out.rgb, gamma);

	//正規化Lambert
	float3 L = normalize( In.wPos - DirLightVec );
	Out.rgb *= ( dot( In.Normal, -L ) * 0.5f + 0.5f ) / PI;

	//正規化Phong
	float3 V = normalize(ViewPos - In.wPos);
	//float3 R = -V + (2.0f * dot(In.Normal, V) * In.Normal);
	//Out.rgb += pow(max(dot(-L, R), .0f), sppower) * ((sppower + 1.0f) / (2.0f * PI)) * tex2D(SpecularSamp, In.Tex) * Roughness;
	//float specular = GGX_PhongCalculate(In.Normal, V, -L, Roughness, Metalness);
	//Out.rgb += specular;

	//逆補正をかけて出力
	Out.rgb = pow( Out.rgb, 1.0f/2.2f );
	return Out;
}

//------------------------------------------------------
//		キューブマップ用ピクセルシェーダー	
//------------------------------------------------------
float4 PS_Cube1( VS_CUBE In ) : COLOR0
{
	float4	Out;
	//	ピクセル色決定
	Out = tex2D( DecaleSamp, In.Tex );

	//キューブマップ
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
	//	ピクセル色決定
	float4 Albedo = tex2D( DecaleSamp, In.Tex );
	Albedo.rgb = pow(Albedo.rgb, gamma);

	//キューブマップ
	float3 EyeR = normalize( reflect( In.Eye, In.Normal ) );
	float3 IBL = texCUBE( CubeSamp, EyeR ).rgb;

	//正規化Lambert
	float3 L = normalize( In.wPos - DirLightVec );
	Albedo.rgb *= ( dot( In.Normal, -L ) * 0.5f + 0.5f ) / PI;

	//正規化Phong
	float3 V = normalize(ViewPos - In.wPos);
	//float specular = GGX_PhongCalculate(In.Normal, V, -L, Roughness, Roughness);

	float3 spcolor = Albedo.rgb * Metalness + float3( 1.0f, 1.0f, 1.0f ) * (1.0f - Metalness);
	//float3 specular = SpecularIBL( spcolor, Roughness, In.Normal, In.Eye );
	Out.rgb = Albedo.rgb +IBL * ( 1.0f - Roughness );
	//Out.rgb += specular;
	Out.rgb = pow( Out.rgb, 1.0f/2.2f );
	return Out;
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

//ガンマ補正あり
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
//		キューブマップ
//------------------------------------------------------

//ガンマ補正なし
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

//ガンマ補正あり
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