//********************************************************************
//																									
//		３Ｄ用シェーダー		
//
//********************************************************************

#include"Utility.fx"

//------------------------------------------------------
//		頂点フォーマット
//------------------------------------------------------
struct VS_OUTPUT
{
    float4 Pos		: POSITION;
    float4 Color	: COLOR0;
    float2 UV		: TEXCOORD0;
};

struct VS_INPUT
{
    float4 Pos    : POSITION;
    float3 Normal : NORMAL;
    float2 UV	  : TEXCOORD0;
};

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
	Out.UV = In.UV;
	Out.Color = 1.0f;

    return Out;
}

//------------------------------------------------------
//		ピクセルシェーダー	
//------------------------------------------------------
float4 PS_Basic( VS_OUTPUT In) : COLOR
{   
	float4	OUT;
	//	ピクセル色決定
	OUT = In.Color * tex2D( DecaleSamp, In.UV );

	return OUT;
}

//------------------------------------------------------
//		通常描画テクニック
//------------------------------------------------------
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

//********************************************************************
//
//		物理ベース		
//
//********************************************************************
#include"PhysicallyBased.fx"