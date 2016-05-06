#include	"iextreme.h"
#include	"system/system.h"
#include	"Character.h"

//-------------------------------------定数宣言とか---------------------------------------------------------

const float Character::SPEED = 0.03f;

//------------------------------------------------------------------------------------------------------------

Character::Character():state(PlayerState::MOVE)
{
}

Character::Character( char* filename, float speed ):state(PlayerState::MOVE)
{
	Init( filename, speed );
}

Character::~Character()
{
	if( m_obj ){ delete m_obj; m_obj = nullptr; }
}

void Character::Init( char* filename, float speed )
{
	m_obj = new Model( filename, speed );
	m_obj -> SetMotion( 0 );
}

void Character::Update()
{
	//状態別行動分岐
	switch( state )
	{
	case PlayerState::MOVE:
		Move();
		break;
	case PlayerState::ATTACK:
			break;
	}

	//angle.y += 0.01f;

	m_obj -> Animation();
	m_obj -> SetScale( m_scale );
	m_obj -> SetAngle( m_angle );
	m_obj -> SetPos( m_pos );
	m_obj -> Update();
}

void Character::Render()
{
	m_obj -> Render();
}

void Character::Render( char* name )
{
	m_obj -> Render( shader, name );
}

/*
	キャラ内で呼び出す関数とか
*/

void Character::ChangeMotion( int motion, float blendspeed )
{
	if( m_obj->GetMotion() == motion ) return;

	m_obj -> SetMotion( motion, blendspeed ); 
}

void Character::Move()
{
	//スティック情報取得
	float AxisX =  KEY_GetAxisX() * 0.01f;
	float AxisY = -KEY_GetAxisY() * 0.01f;
	//軸補正
	if( AxisX*AxisX+AxisY*AxisY < 0.3f*0.3f )
	{
		AxisX = .0f;	AxisY = .0f;
		ChangeMotion( 0, 0.1f );
		return;
	}
	
	//方向ベクトル
	Vector3 front( matView._13, 0, matView._33 );
	front.Normalize();
	Vector3 right( matView._11, 0, matView._31 );
	right.Normalize();
	//移動量
	m_move = ( front*AxisY + right*AxisX ) * SPEED;

	//左右判定
	float x1 = m_move.x; float z1 = m_move.z;
	float x2 = sinf( m_angle.y ); float z2 = cosf( m_angle.y );
	//外積
	float cross = x1*z2 - x2*z1;
	//補正量調整
	float d = sqrtf( x1*x1 + z1*z1 );
	float n = ( x1*x2 + z1*z2 ) / d;
	float adjust = ( 1-n ) * 2.0f;
	if( adjust > 0.3f ) adjust = 0.3f;

	//方向転換
	if( cross < 0 ) m_angle.y -= adjust;
	else m_angle.y += adjust;

	m_pos += m_move;
	ChangeMotion( 1, 0.1f );
}