#ifndef _UTILITY_
#define _UTILITY_

#include"TextureSamplers.fx"

//------------------------------------------------------
//		環境関連
//------------------------------------------------------
float4x4 Projection;	//	投影変換行列
float4x4 TransMatrix;	//	ワールド変換行列
float4x4 matView;		//	カメラ変換行列
float4x4 matProjection; //  投影変換行列
float4x4 InvProjection; //  逆投影変換行列

//円周率
static const float PI = 3.14159265f;

//ディスプレイガンマ値
static const float gamma = 2.2f;

//自然対数の底(ネイピア数)
static const float E = 2.71828f;

//-------------------------------------------------------------------
// @brief スクリーン座標からビュー座標系の位置を算出する
//
// @param UV   スクリーン座標
//
// @return ビュー空間での座標を返す
//-------------------------------------------------------------------
float zFar = 1000.0f;
float4 CalucuViewPosFromScreenPos( in float2 UV )
{
	float4 position = (float4)1.0f;

	position.xy = UV * 2.0f - 1.0f;   //-1から1に戻す
	position.y = -position.y;
	//Depthはビュー空間で格納されてるから一度Projection空間に変換
	float z = tex2D( DepthSamp, UV ).r * zFar;
	float4 projpos_z = mul( float4(0.0, 0.0, z, 1.0), matProjection );
	position.z = projpos_z.z / projpos_z.w;

	//逆行列を掛けてビュー座標系に変換
	position = mul( position, InvProjection );
	position.xyz /= position.w;

	return position;
}

#endif