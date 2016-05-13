#include"Utility.fx"
#include"TextureSamplers.fx"

float testMetalness = 1.0f;  //CPU側から値を持ってくる仮の変数
float testRoughness = 0.1f;  //CPU側から値を持ってくる仮の変数

//********************************************************************
//																									
//		Deferred用G-Buffer作成	
//
//********************************************************************

struct VS_G_BUFFER
{
	float4 Position			: POSITION;
	float2 UV				: TEXCOORD0;
	float3 Normal			: TEXCOORD1;
	float3 BiNormal			: TEXCOORD2;
	float3 Tangent			: TEXCOORD3;
	float4 ViewPos			: TEXCOORD4;
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
	float4x4 mat = mul( TransMatrix, matView );
	Out.ViewPos = mul( In.Pos, mat );

	Out.UV = In.UV;

	//頂点スクリーン座標系算出
	Out.Normal   = mul( In.Normal, (float3x3)TransMatrix );
	Out.Normal   = mul( Out.Normal, (float3x3)matView );
	Out.Normal   = normalize( Out.Normal );
	float3 Y     = { 0, 1, 0.00001 };  //仮のY方向ベクトル
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
	
	//法線をビュー座標系に変換
	float3x3 View;
	View[0] = normalize( In.Tangent );
	View[1] = normalize( In.BiNormal );
	View[2] = normalize( In.Normal );
	float3 N = tex2D( NormalSamp, In.UV ).rgb * 2.0 - 1.0;
	N = mul( N, View );
	N = normalize( N );
	N = N * 0.5 + 0.5;
	Out.Normal = float4( N, 1 );
	
	//float D   = In.ProjectionPos.z / In.ProjectionPos.w;
	float D = In.ViewPos.z / zFar;
	//本来はテクスチャから読み込み
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
//		物理ベース用ライティングBRDF
//
//********************************************************************

//-------------------------------------------------------------------
//
//		ディフューズ項
//
//-------------------------------------------------------------------

//-------------------------------------------------------------------
// @brief エネルギー保存を考慮したLambertの計算
//
// @param Normal   法線
// @param LightDir 光線ベクトル
//
// @return ディフューズライティング結果を返す
//-------------------------------------------------------------------
float3 NormalizeLambert( in const float3 Normal, in const float3 LightDir )
{
	return max( 0, dot( Normal, LightDir ) ) * ( 1.0f / PI );
}

//-------------------------------------------------------------------
// @brief Oren-Nayarモデルの計算
//
// @param Normal    法線
// @param LightDir  光線ベクトル
// @param Eye       視線ベクトル
// @param Roughness 面の質感(つるつるかザラザラか)
//
// @return ディフューズライティング結果を返す
//
// @note Roughnessの値は0.0~1.0を入力する
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
//		スペキュラ項
//
//-------------------------------------------------------------------

//-------------------------------------------------------------------
// @brief Trowbridge-Reitz(GGX)の計算
//
// @param Roughness 面の質感(つるつるかザラザラか)
// @param NoH       法線とハーフベクトルの内積
//
// @return マイクロファセットの分布関数D(h)の計算結果を返す
//
// @note Roughnessの値は0.0~1.0を入力する
//-------------------------------------------------------------------
float GGX( in const float Roughness, in const float NoH )
{
	float alpha = pow( Roughness, 2 );
	float alpha2 = pow( alpha, 2 );
	float NoH2 = pow( saturate( NoH ), 2);
	float D = alpha2 / ( PI * pow( NoH2 * ( alpha - 1 ) + 1, 2 ) );
	return D;
}

//マイクロファセットの分布関数は色々あるみたいやから色々試したい

//-------------------------------------------------------------------
// @brief Schlickの近似式でフレネル反射率の計算
//
// @param F0   フレネル反射率
// @param cosT 
//
// @return フレネル反射率F(v,h)の計算結果を返す
//
//-------------------------------------------------------------------
float3 Fresnel( in const float3 F0, in const float cosT )
{
	return F0 + ( 1 - F0 ) * pow( 1 - cosT, 5 );
}

//ガウシアン球は後で

//-------------------------------------------------------------------
// @brief 幾何減衰率の各項を計算をする
//
// @param Dot       内積
// @param Roughness 面の質感(つるつるかザラザラか)
//
// @return 計算結果を返す
//
//-------------------------------------------------------------------
float G( in const float Dot, in const float Roughness )
{
	float k = pow( Roughness+1, 2 ) / 8;
	return Dot / ( Dot * ( 1 - k ) + k );
}

//-------------------------------------------------------------------
// @brief 幾何減衰率の計算
//
// @param NoL       法線と光線の内積
// @param NoE       法線と視線の内積
// @param Roughness 面の質感(つるつるかザラザラか)
//
// @return 幾何学減衰率G(l,v,h)の計算結果を返す
//
// @note Roughnessの値は0.0~1.0を入力する
// @note 1はIBL用2はポイントライトとか用
//-------------------------------------------------------------------
float Geometric( in const float NoL, in const float NoE, in const float Roughness )
{
	return G( NoL, Roughness ) * G( NoE, Roughness );
}

//-------------------------------------------------------------------
// @brief CookTorranceの計算( D(h)F(v,h)G(l,v,h) / 4(n・l)(n・v) )
//
// @param Normal    法線
// @param LightDir  光線ベクトル
// @param Eye       視線ベクトル
// @param Roughness 面の質感(つるつるかザラザラか)
// @param F0        フレネル反射率
//
// @return スペキュラライティングの結果を返す
//
// @note Roughnessの値は0.0~1.0を入力する
//-------------------------------------------------------------------
float3 CookTorrance( in const float3 Normal, in const float3 LightDir, in const float3 Eye,
	               in const float Roughness, in const float3 F0 )
{
	//HalfVector
	float3 H = normalize( LightDir + Eye );
	float NoE = saturate( dot( Normal, Eye ) );
	float NoL = saturate( dot( Normal, LightDir ) );
	float NoH = saturate( dot( Normal, H ) );
	float LoH = saturate( dot( LightDir, H ) );
	float EoH = saturate( dot( Eye, H ) );

	//マイクロファセッとの分布関数D(h)
	float D = GGX( Roughness, NoH );

	//フレネル反射率F(v,h)
	float3 F = Fresnel( F0, LoH );

	//幾何減衰率項G(l,v,h)
	float G = Geometric( NoL, NoE, Roughness );

	return ( D * F * G ) / ( 4 * NoL * NoE );
}

//********************************************************************
//																									
//		Deferred用DirLight
//
//********************************************************************

struct PS_DEFERRED
{
	float4 Color    : COLOR0;
	float4 Specular : COLOR1;
	float4 IBL      : COLOR2;
};

float3 LightPos = { 100.0f, 100.0f, 100.0f };
float3 LightVec = { 1.0f, -1.0f, 1.0f };
float3 LightColor = { 1.0f, 1.0f, 1.0f };
float  LightFlux = 10000.0f;

PS_DEFERRED PS_DirLight( float2 UV : TEXCOORD0 ) : COLOR
{
	PS_DEFERRED Out = ( PS_DEFERRED )0;

    //遠い奴はは空としてライティングをスキップ(そのうち直す)
    if( tex2D( DepthSamp, UV ).r >= 0.3f )
	{
		Out.Color    = float4( 1.0f, 1.0f, 1.0f, 1.0f );
		Out.Specular = float4( 0.0f, 0.0f, 0.0f, 0.0f );
		Out.IBL      = float4( 1.0f, 1.0f, 1.0f, 1.0f );
		return Out;
	}

    //BaseColor
    float4 BaseColor = tex2D( ColorSamp, UV );
    
    float4 Position = CalucuViewPosFromScreenPos( UV );
	float3 Eye = normalize( -Position.xyz );

	//Lightの位置から距離で輝度を求める
	float4 LightViewPos = mul( float4( LightPos, 1.0f ), matView );
	float dist = length( Position.xyz - LightViewPos.xyz );
	float falloff = 1 / (pow(dist, 2 ) + 1);    //分母の＋１は０除算回避用

	//光線ベクトルもビュー空間で計算
    float3 Light = normalize( mul( -LightVec, (float3x3)matView ) );
    //法線マップから法線の取得
    float3 Normal = tex2D( NormalSamp, UV ).xyz * 2.0f - 1.0f;
	Normal = normalize( Normal );
	//反射ベクトル
	float3 Reflect = reflect( -Eye, Normal );
	Reflect = normalize( Reflect );

	//同じようにラフネス、メタルネスも取得
	float Metalness = tex2D( MRSamp, UV ).r;
	float Roughness = tex2D( MRSamp, UV ).g;

	//Diffuse
	float3 Diffuse = LightColor * OrenNayar( Normal, Light, Eye, Roughness ); //OrenNayar
	//float3 Diffuse = LightColor * NormalizeLambert( Normal, Light ); //正規化ランバート

	//Specular
	float3 SpecularColor = lerp( float3( 1.0f, 1.0f, 1.0f ), BaseColor.rgb, Metalness );
	float3 Specular = CookTorrance( Normal, Light, Eye, Roughness, SpecularColor );

	//出力
	Out.Color.rgb = Diffuse * ( 1.0f - Metalness );  //Specularとの総和が１を超えないように
	Out.Color.a = 1.0f;
	Out.Specular.rgb = Specular * Metalness;         //Diffuseとの総和が１を超えないように
	Out.Specular.a = 1.0f;

	Out.IBL = texCUBEbias( CubeSamp, float4(Reflect, Roughness * (MaxMipMaplevel + 1)) );
    
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
//		合成
//
//********************************************************************

float4 PS_Deferred( float2 UV : TEXCOORD0 ) : COLOR0
{
	float4 Out = (float4)1.0f;

	Out = tex2D( ColorSamp, UV );
	Out.rgb = pow( Out.rgb, gamma );		//ディスプレイガンマを考慮して補正

	Out.rgb *= tex2D( LightSamp, UV ).rgb;

	Out.rgb += tex2D( SpecularSamp, UV ).rgb;

	//Out.rgb *= tex2D( IBLSamp, UV ).rgb;

	Out.rgb = pow( Out.rgb, 1.0f / gamma ); //ディスプレイガンマの逆補正をかけて出力
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