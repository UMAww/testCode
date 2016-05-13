#ifndef _UTILITY_
#define _UTILITY_

#include"TextureSamplers.fx"

//------------------------------------------------------
//		���֘A
//------------------------------------------------------
float4x4 Projection;	//	���e�ϊ��s��
float4x4 TransMatrix;	//	���[���h�ϊ��s��
float4x4 matView;		//	�J�����ϊ��s��
float4x4 matProjection; //  ���e�ϊ��s��
float4x4 InvProjection; //  �t���e�ϊ��s��

//�~����
static const float PI = 3.14159265f;

//�f�B�X�v���C�K���}�l
static const float gamma = 2.2f;

//���R�ΐ��̒�(�l�C�s�A��)
static const float E = 2.71828f;

//-------------------------------------------------------------------
// @brief �X�N���[�����W����r���[���W�n�̈ʒu���Z�o����
//
// @param UV   �X�N���[�����W
//
// @return �r���[��Ԃł̍��W��Ԃ�
//-------------------------------------------------------------------
float zFar = 1000.0f;
float4 CalucuViewPosFromScreenPos( in float2 UV )
{
	float4 position = (float4)1.0f;

	position.xy = UV * 2.0f - 1.0f;   //-1����1�ɖ߂�
	position.y = -position.y;
	//Depth�̓r���[��ԂŊi�[����Ă邩���xProjection��Ԃɕϊ�
	float z = tex2D( DepthSamp, UV ).r * zFar;
	float4 projpos_z = mul( float4(0.0, 0.0, z, 1.0), matProjection );
	position.z = projpos_z.z / projpos_z.w;

	//�t�s����|���ăr���[���W�n�ɕϊ�
	position = mul( position, InvProjection );
	position.xyz /= position.w;

	return position;
}

#endif