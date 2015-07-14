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
//		GGXを用いたスペキュラ計算		
//
//********************************************************************
static const float PI = 3.14159265f;
static const float OneDivPI = 1 / PI;
static float gamma = 2.2f;

float3 ImportanveSampleGGX( float2 Xi, float roughness, float3 Normal )
{
	float alpha = roughness * roughness;
	float Phi = 2 * PI * Xi.x;
	float CosTheta = sqrt( (1-Xi.y) / (1+(alpha*alpha - 1)+Xi.y));
	float SinTheta = sqrt( 1 - CosTheta * CosTheta );

	float3 H;
	H.x = SinTheta * cos( Phi );
	H.y = SinTheta * sin( Phi );
	H.z = CosTheta;

	float3 Up = abs(Normal.z) < 0.999 ? float3(0,0,1) : float3(1,0,0);
	float3 TangentX = normalize( cross( Up, Normal ));
	float3 TangentY = cross( Normal, TangentX );

	return TangentX * H.x + TangentY * H.y + Normal * H.z;
}

float radicalInverse_VdC( uint bits )
{
	bits = ( bits << 16u ) | ( bits >> 16u );
	bits = ( (bits & 0x55555555u) << 1u ) | ( (bits & 0xAAAAAAAAu) >> 1u );
	bits = ( (bits & 0x33333333u) << 2u ) | ( (bits & 0xCCCCCCCCu) >> 2u );
	bits = ( (bits & 0x0F0F0F0Fu) << 4u ) | ( (bits & 0xF0F0F0F0u) >> 4u );
	bits = ( (bits & 0x00FF00FFu) << 8u ) | ( (bits & 0xFF00FF00u) >> 8u );
	return float(bits) * 2.3283064365386963e-10;
}

float2 Hammersley( uint i, uint N )
{
	return float2( float(i)/float(N), radicalInverse_VdC(i));
}

float GGX( float NdotE, float a )
{
	float k = a / 2;
	return NdotE / ( NdotE * (1.0f-k) + k );
}

float G_Smith( float a, float NdotE, float NdotL )
{
	return GGX( NdotL, a*a ) * GGX( NdotE, a*a );
}

static const uint NumSamples = 1024; 
float3 SpecularIBL( float3 SpeColor, float roughness, float3 Normal, float3 Eye )
{
	float3 SpecularLighting = 0;

	for( uint i = 0; i < NumSamples; i++ )
	{
		float2 Xi = Hammersley( i, NumSamples );
		float3 H = ImportanveSampleGGX( Xi, roughness, Normal );
		float3 L = 2 * dot( Eye, H ) * H - Eye;
		
		float NoE = saturate( dot( Normal, Eye ) );
		float NoL = saturate( dot( Normal, L ) );
		float NoH = saturate( dot( Normal, H ) );
		float EoH = saturate( dot( Eye, H ) );

		if( NoL > 0 )
		{
			float3 SampleColor = texCUBElod(CubeSamp, float4(L, 0) ).rgb;

			float G = G_Smith( roughness, NoE, NoL );
			float Fc = pow( 1 - EoH, 5 );
			float3 F = ( 1 - Fc ) * SpeColor + Fc;

				SpecularLighting += SampleColor * F * G * EoH / ( NoH * NoE );
		}
	}

	return SpecularLighting / NumSamples;
}

static float TotalWeight = .0f;
float3 PrefilterEnvMap( float roughness, float3 R )
{
	float3 N = R;
	float3 V = R;

	float3 PrefilterColor = 0;

	for( uint i = 0; i < NumSamples; i++ )
	{
		float2 Xi = Hammersley( i, NumSamples );
		float3 H = ImportanveSampleGGX( Xi, roughness, N );
		float3 L = 2 + dot( V, H ) * H - V;
		float NoL = saturate( dot( N, L ) );
		if( NoL > 0 )
		{
			PrefilterColor += texCUBElod(CubeSamp, float4(L, 0 ) ).rgb * NoL;
			TotalWeight += NoL;
		}
	}

	return PrefilterColor / TotalWeight;
}

float2 IntegrateBRDF( float roughness, float NoE )
{
	float3 V;
	V.x = sqrt( 1.0f - NoE * NoE ); //sin
	V.y = .0f;
	V.z = NoE;						//cos

	float A = .0f; float B = .0f;

	for( uint i = 0; i < NumSamples; i++ )
	{
		float2 Xi = Hammersley( i, NumSamples );
		float3 H = ImportanveSampleGGX( Xi, roughness, float3( 0, 0, 1 ) );
		float3 L = 2 * dot( V, H ) * H - V;

		float NoL = saturate( L.z );
		float NoH = saturate( H.z );
		float VoH = saturate( dot( V, H ) );
		if( NoL > 0 )
		{
			float G = G_Smith( roughness, NoE, NoL );
			float G_Vis = G * VoH / (NoH*NoE);
			float Fc = pow( 1 - VoH, 5 );
			A += (1-Fc) * G_Vis;
			B += Fc * G_Vis;
		}
	}

	return float2( A, B ) / NumSamples;
}

float3 ApproximateSpecularIBL( float3 SpecColor, float roughness, float3 Normal, float3 Eye )
{
	float NoE = saturate( dot( Normal, Eye ) );
	float3 R = 2 * dot( Eye, Normal ) * Normal - Eye;
	float3 PrefilteredColor = PrefilterEnvMap( roughness, R );
	float2 EnvBRDF = IntegrateBRDF( roughness, NoE );

	return PrefilteredColor * ( SpecColor * EnvBRDF.x + EnvBRDF.y );
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
	//metalnessによってspecularカラーとalbedoカラーの決定
	float4 specularColor = float4(lerp(0.04f.rrr, Albedo.rgb, 1-Metalness ), 1.0f );
	Albedo.rgb = lerp( Albedo.rgb, 0.0f.rrr,1- Metalness );
	Albedo = pow( Albedo, gamma );

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

	Out = pow( abs( Out ), 1.0/gamma );
	Out.a = 1.0;

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