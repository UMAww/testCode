//**************************************************************************************************
//																									
//		�Q�c�`��p�V�F�[�_�[		
//
//**************************************************************************************************

//------------------------------------------------------
//		�e�N�X�`���T���v���[	
//------------------------------------------------------
texture Texture;
sampler DecaleSamp = sampler_state
{
    Texture = <Texture>;
    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = NONE;

    AddressU = Wrap;
    AddressV = Wrap;
};

//------------------------------------------------------
//		���_�t�H�[�}�b�g
//------------------------------------------------------
struct VS_2D
{
    float4 Pos		: POSITION;
    float4 Color	: COLOR0;
    float2 Tex		: TEXCOORD0;
};

//**************************************************************************************************
//		�Q�c��{�`��V�F�[�_�[		
//**************************************************************************************************
//------------------------------------------------------
//		�s�N�Z���V�F�[�_�[	
//------------------------------------------------------
float4 PS_Basic( VS_2D In) : COLOR
{   
	float4	OUT;

	//	�s�N�Z���F����
	OUT = In.Color * tex2D( DecaleSamp, In.Tex );

	return OUT;
}

//------------------------------------------------------
//		�����Ȃ�	
//------------------------------------------------------
technique copy
{
    pass P0
    {
		AlphaBlendEnable = true;
		BlendOp          = Add;
		SrcBlend         = SrcAlpha;
		DestBlend        = InvSrcAlpha;
		CullMode         = None;
		ZEnable          = false;

		PixelShader  = compile ps_2_0 PS_Basic();
    }
}

//------------------------------------------------------
//		���Z����
//------------------------------------------------------
technique add
{
    pass P0
    {
		AlphaBlendEnable = true;
		BlendOp          = Add;
		SrcBlend         = SrcAlpha;
		DestBlend        = One;
		CullMode         = None;
		ZEnable          = false;

		PixelShader  = compile ps_2_0 PS_Basic();
    }
}
//------------------------------------------------------
//		���Z����
//------------------------------------------------------
technique sub
{
    pass P0
    {
		AlphaBlendEnable = true;
		BlendOp          = RevSubtract;
		SrcBlend         = SrcAlpha;
		DestBlend        = One;
		CullMode         = None;
		ZEnable          = false;

		PixelShader  = compile ps_2_0 PS_Basic();
    }
}

//------------------------------------------------------
//		�ڂ���
//------------------------------------------------------

//1pixel�̒l
float offset = 10.0f;

float4 PS_BlurX( VS_2D In ) : COLOR
{

	float4 Out;

	float Offset = offset / 512.0f;

	Out  = In.Color * tex2D( DecaleSamp, In.Tex ) * .2f;
	Out += In.Color * tex2D( DecaleSamp, In.Tex + float2( -Offset*1, 0.0f ) ) * .12f;
	Out += In.Color * tex2D( DecaleSamp, In.Tex + float2( -Offset*2, 0.0f ) ) * .10f;
	Out += In.Color * tex2D( DecaleSamp, In.Tex + float2( -Offset*3, 0.0f ) ) * .08f;
	Out += In.Color * tex2D( DecaleSamp, In.Tex + float2( -Offset*4, 0.0f ) ) * .06f;
	Out += In.Color * tex2D( DecaleSamp, In.Tex + float2( -Offset*5, 0.0f ) ) * .04f;
						  
	Out += In.Color * tex2D( DecaleSamp, In.Tex + float2(  Offset*1, 0.0f ) ) * .12f;
	Out += In.Color * tex2D( DecaleSamp, In.Tex + float2(  Offset*2, 0.0f ) ) * .10f;
	Out += In.Color * tex2D( DecaleSamp, In.Tex + float2(  Offset*3, 0.0f ) ) * .08f;
	Out += In.Color * tex2D( DecaleSamp, In.Tex + float2(  Offset*4, 0.0f ) ) * .06f;
	Out += In.Color * tex2D( DecaleSamp, In.Tex + float2(  Offset*5, 0.0f ) ) * .04f;

	Out.a = 1.0f;

	return Out;

}

float4 PS_BlurY( VS_2D In )	:	COLOR
{
	float4 Out;

	float Offset = offset / 512.0f;

	Out  = In.Color * tex2D( DecaleSamp, In.Tex ) * .2f;
	Out += In.Color * tex2D( DecaleSamp, In.Tex + float2( 0.0f, -Offset*1 ) ) * .12f;
	Out += In.Color * tex2D( DecaleSamp, In.Tex + float2( 0.0f, -Offset*2 ) ) * .10f;
	Out += In.Color * tex2D( DecaleSamp, In.Tex + float2( 0.0f, -Offset*3 ) ) * .08f;
	Out += In.Color * tex2D( DecaleSamp, In.Tex + float2( 0.0f, -Offset*4 ) ) * .06f;
	Out += In.Color * tex2D( DecaleSamp, In.Tex + float2( 0.0f, -Offset*5 ) ) * .04f;
					  
	Out += In.Color * tex2D( DecaleSamp, In.Tex + float2( 0.0f,  Offset*1 ) ) * .12f;
	Out += In.Color * tex2D( DecaleSamp, In.Tex + float2( 0.0f,  Offset*2 ) ) * .10f;
	Out += In.Color * tex2D( DecaleSamp, In.Tex + float2( 0.0f,  Offset*3 ) ) * .08f;
	Out += In.Color * tex2D( DecaleSamp, In.Tex + float2( 0.0f,  Offset*4 ) ) * .06f;
	Out += In.Color * tex2D( DecaleSamp, In.Tex + float2( 0.0f,  Offset*5 ) ) * .04f;

	Out.a = 1.0f;

	return Out;
}

technique blur
{

	pass P0
	{
		AlphaBlendEnable = true;
		BlendOp			 = Add;
		SrcBlend		 = SrcAlpha;
		DestBlend		 = InvSrcAlpha;
		CullMode		 = NONE;
		ZEnable			 = false;
		// �V�F�[�_
		//VertexShader = compile vs_2_0 VS_Basic();
		PixelShader = compile ps_2_0 PS_BlurX();
	}
	pass P1
	{
		AlphaBlendEnable = true;
		BlendOp			 = Add;
		SrcBlend		 = SrcAlpha;
		DestBlend		 = InvSrcAlpha;
		CullMode		 = NONE;
		ZEnable			 = false;
		// �V�F�[�_
		//VertexShader = compile vs_2_0 VS_Basic();
		PixelShader = compile ps_2_0 PS_BlurY();
	}
}