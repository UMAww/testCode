#include	"iextreme.h"
#include	"system/system.h"
#include	"Camera.h"

//const float Camera::DIST = 50.0f;
const float Camera::SPEED = 0.005f;
const float Camera::UPLIMIT = 0.5f;
const float Camera::DOWNLIMIT = 3.0f;

Camera::Camera() : view(nullptr), pos( 0, 0, 0 ), angle( .0f, .0f, .0f ), DIST( 20.0f )
{
	view = new iexView();
	D3DXQuaternionIdentity(&targetQ);
	D3DXQuaternionIdentity(&currentQ);
	Vector3 work( 0, 0.5, -1 );
	work.Normalize();
	lPos.x = pos.x + work.x;
	lPos.y = pos.y + work.y * 10.0f;
	lPos.z = pos.z + work.z * 20.0f;
}

Camera::Camera( Vector3 pos, Vector3 target ) : view(nullptr), angle( .0f, .0f, .0f )
{
	view = new iexView();
	D3DXQuaternionIdentity(&targetQ);
	D3DXQuaternionIdentity(&currentQ);

	this->pos = pos;
	this->target = target;

	Vector3 work( 0, 0.5, -1 );
	work.Normalize();
	lPos.x = pos.x + work.x;
	lPos.y = pos.y + work.y * 10.0f;
	lPos.z = pos.z + work.z * 20.0f;
}

Camera::~Camera()
{
	if( view ){ delete view; view = nullptr; }
}

void Camera::Update( const Vector3& pos )
{
	//ターゲット更新
	target = pos;
	target.y += 5.0f;

	Rotate();

	Vector3 v = target - this->pos;
	float d = v.Length();
	
	if( d > DIST || d < DIST ) this->pos = target - v/d*DIST;

	//位置更新
	view -> Set( this->pos, target );
	shader -> SetValue( "ViewPos", this->pos );

}

void Camera::Clear( long color )
{
	view -> Activate();
	view -> Clear( color );
}

void Camera::ClearScreen( long color )
{
	view -> Clear();
}

void Camera::Set( const Vector3& pos, const Vector3& target )
{
	this->pos = pos;
	this->target = target;
	view -> Set( this->pos, this->target );
	shader -> SetValue( "ViewPos", this->pos );
}

void Camera::Rotate()
{
	D3DXQUATERNION rot;
	D3DXQuaternionIdentity(&rot);

	Matrix mat = ::matView;

	D3DXVECTOR3 up( 0, 1, 0 );
	D3DXVECTOR3 right( mat._11, mat._21, mat._31 );
	D3DXVec3Normalize( &right, &right );

	//スティック情報取得
	float AxisX =  KEY_GetAxisX2() * 0.01f;
	float AxisY =  KEY_GetAxisY2() * 0.01f;
	//軸補正
	if( AxisX*AxisX < 0.3f*0.3f ) AxisX = .0f;
	if( AxisY*AxisY < 0.3f*0.3f ) AxisY = .0f;

	//水平回転
	D3DXQuaternionRotationAxis( &rot, &up, AxisX*SPEED );
	targetQ *= rot;

	//垂直回転
	D3DXQuaternionRotationAxis( &rot, &right, AxisY*SPEED );
	targetQ *= rot;

	D3DXQUATERNION work( lPos.x, lPos.y, lPos.z, 0 );

	D3DXQUATERNION invW;
	D3DXQuaternionConjugate(&invW, &targetQ);

	//回転
	work = invW * work * targetQ;

	D3DXVECTOR3 vec(work.x, work.y, work.z);
	D3DXVec3Normalize( &vec, &vec );

	float angle;

	//真上方向のベクトルとの内積で回転角度の制限を行う
	angle = acosf( D3DXVec3Dot( &up, &vec ) );
	if ( angle < UPLIMIT )
	{
		D3DXVECTOR3 temp(-mat._11, -mat._21, -mat._31);
		D3DXVec3Normalize( &temp, &temp );
		D3DXQUATERNION q;
		D3DXQuaternionRotationAxis( &q, &temp, UPLIMIT - angle );
		targetQ *= q;
	}

	if ( DOWNLIMIT < angle )
	{
		D3DXVECTOR3 temp(mat._11, mat._21, mat._31);
		D3DXVec3Normalize( &temp, &temp );
		D3DXQUATERNION q;
		D3DXQuaternionRotationAxis( &q, &temp, angle - DOWNLIMIT );
		targetQ *= q;
	}

	D3DXQUATERNION q_pos( lPos.x, lPos.y, lPos.z, 0 );
	D3DXQUATERNION inverce_Q;
	//軸が逆のクォータニオンを生成
	D3DXQuaternionConjugate( &inverce_Q, &targetQ );
	//球面線形補間
	D3DXQuaternionSlerp( &currentQ, &currentQ, &targetQ, 0.15f );

	//回転
	q_pos = inverce_Q * q_pos * currentQ;
	pos = Vector3( q_pos.x, q_pos.y, q_pos.z );
	//ワールド空間に変換
	pos = target + pos;

}