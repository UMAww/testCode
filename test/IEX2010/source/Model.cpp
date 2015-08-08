#include	"iextreme.h"
#include	"Model.h"

Model::Model( char* filename, float speed )
	: iex3DObj( filename ),
	interpolationMotionNo(0),interpolationMotionFrame(0),
	interpolationRate(.0f),interpolationSpeed(.0f),fFrame(.0f)
{
	motionSpeed = speed;
}

Model::~Model()
{
}

Model* Model::Clone()
{
	Model*	obj = new Model(*this);
	obj->SetLoadFlag(FALSE);
	return obj;
}

void Model::Animation()
{
	fFrame += motionSpeed;
	if( fFrame >= 1.0f )
	{
		fFrame -= 1.0f;

		int		param;
		u32	work;
		if (dwFrame == 356)
			int a = 0;

		work = dwFrame;
		if (work == 356)
			int a = 0;
		param = dwFrameFlag[dwFrame];
		if (param & 0x4000)
			param = 0xFFFF;
		if (param != 0xFFFF){
			//	アニメーションジャンプ
			if (param & 0x8000){
				iex3DObj::SetMotion(param & 0xFF);
			}
			else dwFrame = param;
		}
		else {
			dwFrame++;
			if (dwFrame >= NumFrame) dwFrame = 0;
		}

		if (dwFrame != work) bChanged = TRUE;

		param = dwFrameFlag[dwFrame];
		if ((param != 0xFFFF) && (param & 0x4000)) Param[(param & 0x0F00) >> 8] = (u8)(param & 0x00FF);

		//ブレンドモーションもアニメーション
		work = interpolationMotionFrame;
		param = dwFrameFlag[interpolationMotionFrame];
		if (param & 0x4000)
			param = 0xFFFF;
		if (param != 0xFFFF)
		{
			if (param & 0x8000)
			{
				interpolationMotionNo = param & 0xFF;
				interpolationMotionFrame = M_Offset[param & 0xFF];
			}
			else
				interpolationMotionFrame = param;
		}
		else
		{
			interpolationMotionFrame++;
			if (interpolationMotionFrame >= NumFrame)
				interpolationMotionFrame = 0;
		}

		if (interpolationRate > .0f)
		{
			interpolationRate -= interpolationSpeed;
			if (interpolationRate <= .0f)
			{
				interpolationRate = .0f;
				interpolationSpeed = .0f;
			}
		}
		param = dwFrameFlag[dwFrame];
		if ((param != 0xFFFF) && (param & 0x4000))
			Param[(param & 0x0F00) >> 8] = (u8)(param & 0x00FF);
	}
}

void Model::UpdateSkinMeshFrame()
{
	u32			i, j;
	LPIEXANIME2	lpAnime;
	float		t;
	float frame1 = (float)dwFrame;
	if (frame1 >= 300)
		int a = 0;

	for (i = 0; i < NumBone; i++)
	{
		lpAnime = &this->lpAnime[i];

		//	ポーズ設定
		if (lpAnime->rotNum == 0) CurPose[i] = orgPose[i];
		else if (lpAnime->rotNum == 1) CurPose[i] = lpAnime->rot[0];
		else 
		{
			//	回転キー補間
			for (j = 0; j < lpAnime->rotNum - 1; j++)
			{
				//	現在位置検索
				if ((frame1 >= lpAnime->rotFrame[j]) && (frame1<lpAnime->rotFrame[j + 1]))
				{
					//	経過フレーム計算
					t = (float)(frame1 - lpAnime->rotFrame[j]) / (float)(lpAnime->rotFrame[j + 1] - lpAnime->rotFrame[j]);
					//	補間
					CurPose[i] = QuaternionSlerp(lpAnime->rot[j], lpAnime->rot[j + 1], t);
					break;
				}
			}
			if (j == lpAnime->rotNum - 1) CurPose[i] = lpAnime->rot[lpAnime->rotNum - 1];
		}
		//	座標設定
		if (lpAnime->posNum == 0) CurPos[i] = orgPos[i];
		else
		{
			//	位置補間
			for (j = 0; j<lpAnime->posNum - 1; j++)
			{
				//	現在位置検索
				if ((frame1 >= lpAnime->posFrame[j]) && (frame1<lpAnime->posFrame[j + 1]))
				{
					//	経過フレーム計算
					t = (float)(frame1 - lpAnime->posFrame[j]) / (float)(lpAnime->posFrame[j + 1] - lpAnime->posFrame[j]);
					//	補間
					CurPos[i] = lpAnime->pos[j] + (lpAnime->pos[j + 1] - lpAnime->pos[j])*t;
					break;
				}
			}
			if (j == lpAnime->posNum - 1) CurPos[i] = lpAnime->pos[lpAnime->posNum - 1];
		}
	}

	//ブレンドモーションアニメーション
	Quaternion	tempq;
	float frame2 = (float)interpolationMotionFrame;
	for (i = 0; i < NumBone; i++)
	{
		lpAnime = &this->lpAnime[i];

		//	ポーズ設定
		if (lpAnime->rotNum == 0)
			CurPose[i] = orgPose[i];
		else if (lpAnime->rotNum == 1) CurPose[i] = lpAnime->rot[0];
		else
		{
			//	回転キー補間
			for (j = 0; j < lpAnime->rotNum - 1; j++)
			{
				//	現在位置検索
				if ((frame2 >= lpAnime->rotFrame[j]) && (frame2<lpAnime->rotFrame[j + 1]))
				{
					//	経過フレーム計算
					t = (float)(frame2 - lpAnime->rotFrame[j]) / (float)(lpAnime->rotFrame[j + 1] - lpAnime->rotFrame[j]);
					//	補間
					tempq = QuaternionSlerp(lpAnime->rot[j], lpAnime->rot[j + 1], t);
					CurPose[i] = QuaternionSlerp(CurPose[i], tempq, interpolationRate);
					break;
				}
			}
		}
		//	座標設定
		if (lpAnime->posNum == 0)
			CurPos[i] = orgPos[i];
		else
		{
			//	位置補間
			for (j = 0; j<lpAnime->posNum - 1; j++)
			{
				//	現在位置検索
				if ((frame2 >= lpAnime->posFrame[j]) && (frame2<lpAnime->posFrame[j + 1]))
				{
					//	経過フレーム計算
					t = (float)(frame2 - lpAnime->posFrame[j]) / (float)(lpAnime->posFrame[j + 1] - lpAnime->posFrame[j]);
					//	補間
					Vector3 temppos;
					temppos = lpAnime->pos[j] + (lpAnime->pos[j + 1] - lpAnime->pos[j])*t;
					CurPos[i] = CurPos[i] + (temppos - CurPos[i]) * interpolationRate;
					break;
				}
			}
		}
	}
}

void Model::Update()
{
	UpdateSkinMeshFrame();
	UpdateBoneMatrix();
	UpdateSkinMesh();

	iexMesh::Update();
	RenderFrame = dwFrame;
	bChanged = FALSE;
}

void Model::SetMotion( const int nextMotion, float blendSpeed )
{
	if( M_Offset[nextMotion] == 65535 ) return;

	int param;

	interpolationMotionNo = Motion;
	interpolationMotionFrame = dwFrame;

	Motion = nextMotion;
	dwFrame = M_Offset[nextMotion];
	bChanged = TRUE;

	interpolationRate = 1.0f;
	interpolationSpeed = blendSpeed;

	param = dwFrameFlag[dwFrame];
	if ((param != 0xFFFF) && (param & 0x4000)) Param[(param & 0x0F00) >> 8] = (u8)(param & 0x00FF);
}