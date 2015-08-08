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
			//	�A�j���[�V�����W�����v
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

		//�u�����h���[�V�������A�j���[�V����
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

		//	�|�[�Y�ݒ�
		if (lpAnime->rotNum == 0) CurPose[i] = orgPose[i];
		else if (lpAnime->rotNum == 1) CurPose[i] = lpAnime->rot[0];
		else 
		{
			//	��]�L�[���
			for (j = 0; j < lpAnime->rotNum - 1; j++)
			{
				//	���݈ʒu����
				if ((frame1 >= lpAnime->rotFrame[j]) && (frame1<lpAnime->rotFrame[j + 1]))
				{
					//	�o�߃t���[���v�Z
					t = (float)(frame1 - lpAnime->rotFrame[j]) / (float)(lpAnime->rotFrame[j + 1] - lpAnime->rotFrame[j]);
					//	���
					CurPose[i] = QuaternionSlerp(lpAnime->rot[j], lpAnime->rot[j + 1], t);
					break;
				}
			}
			if (j == lpAnime->rotNum - 1) CurPose[i] = lpAnime->rot[lpAnime->rotNum - 1];
		}
		//	���W�ݒ�
		if (lpAnime->posNum == 0) CurPos[i] = orgPos[i];
		else
		{
			//	�ʒu���
			for (j = 0; j<lpAnime->posNum - 1; j++)
			{
				//	���݈ʒu����
				if ((frame1 >= lpAnime->posFrame[j]) && (frame1<lpAnime->posFrame[j + 1]))
				{
					//	�o�߃t���[���v�Z
					t = (float)(frame1 - lpAnime->posFrame[j]) / (float)(lpAnime->posFrame[j + 1] - lpAnime->posFrame[j]);
					//	���
					CurPos[i] = lpAnime->pos[j] + (lpAnime->pos[j + 1] - lpAnime->pos[j])*t;
					break;
				}
			}
			if (j == lpAnime->posNum - 1) CurPos[i] = lpAnime->pos[lpAnime->posNum - 1];
		}
	}

	//�u�����h���[�V�����A�j���[�V����
	Quaternion	tempq;
	float frame2 = (float)interpolationMotionFrame;
	for (i = 0; i < NumBone; i++)
	{
		lpAnime = &this->lpAnime[i];

		//	�|�[�Y�ݒ�
		if (lpAnime->rotNum == 0)
			CurPose[i] = orgPose[i];
		else if (lpAnime->rotNum == 1) CurPose[i] = lpAnime->rot[0];
		else
		{
			//	��]�L�[���
			for (j = 0; j < lpAnime->rotNum - 1; j++)
			{
				//	���݈ʒu����
				if ((frame2 >= lpAnime->rotFrame[j]) && (frame2<lpAnime->rotFrame[j + 1]))
				{
					//	�o�߃t���[���v�Z
					t = (float)(frame2 - lpAnime->rotFrame[j]) / (float)(lpAnime->rotFrame[j + 1] - lpAnime->rotFrame[j]);
					//	���
					tempq = QuaternionSlerp(lpAnime->rot[j], lpAnime->rot[j + 1], t);
					CurPose[i] = QuaternionSlerp(CurPose[i], tempq, interpolationRate);
					break;
				}
			}
		}
		//	���W�ݒ�
		if (lpAnime->posNum == 0)
			CurPos[i] = orgPos[i];
		else
		{
			//	�ʒu���
			for (j = 0; j<lpAnime->posNum - 1; j++)
			{
				//	���݈ʒu����
				if ((frame2 >= lpAnime->posFrame[j]) && (frame2<lpAnime->posFrame[j + 1]))
				{
					//	�o�߃t���[���v�Z
					t = (float)(frame2 - lpAnime->posFrame[j]) / (float)(lpAnime->posFrame[j + 1] - lpAnime->posFrame[j]);
					//	���
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