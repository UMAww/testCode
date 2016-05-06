#include	"iextreme.h"
//#include	"system/system.h"
#include	"Object.h"

//-------------------------------------定数宣言とか---------------------------------------------------------

const float Object::SPEED = 0.01f;

//------------------------------------------------------------------------------------------------------------

Object::Object() : m_obj( nullptr ), m_move( .0f, .0f, .0f ), m_vec( .0f ), m_metalness(1.0f), m_roughness( 0.0f ), m_isEnable( true )
{
}

Object::Object( iexMesh* obj ): m_obj( nullptr ), m_move( .0f, .0f, .0f ), m_vec( .0f ), m_metalness( 1.0f ), m_roughness( 0.0f ), m_isEnable( true )
{
	m_obj = obj->Clone();
}

Object::Object( char* filename ) : m_obj( nullptr ), m_move( .0f, .0f, .0f ), m_vec( .0f ), m_metalness(1.0f), m_roughness( 0.0f ), m_isEnable( true )
{
	m_obj = new iexMesh( filename );
	this->m_pos = this->m_angle = Vector3( .0f, .0f, .0f );
	this->m_scale = Vector3( 1.0f, 1.0f, 1.0f );
	m_obj->SetScale( this->m_scale );
	m_obj->SetAngle( this->m_angle );
	m_obj->SetPos( this->m_pos );
	m_obj->Update();
}

Object::Object( char* filename, Vector3 pos, Vector3 angle, Vector3 scale ) : m_obj( nullptr ), m_move( .0f, .0f, .0f ), m_vec( .0f ), m_metalness(1.0f), m_roughness( 0.0f ), m_isEnable( true )
{
	m_obj = new iexMesh( filename );
	this->m_pos = pos;
	this->m_angle = angle;
	this->m_scale = scale;
	m_obj->SetScale( this->m_scale );
	m_obj->SetAngle( this->m_angle );
	m_obj->SetPos( this->m_pos );
	m_obj->Update();
}

Object::~Object()
{
	if( m_obj ){ delete m_obj; m_obj = nullptr; }
}

void Object::Init( char* filename )
{
	m_obj = new iexMesh( filename );
}

void Object::Update()
{
	//移動
	//Move();

	//angle.y += 0.01f;
	//if( KEY_Get( KEY_A ) ){ roughness += 0.003f; }
	//if( KEY_Get( KEY_B ) ){ roughness -= 0.003f; }
	//if( roughness <= .0f ){ roughness = .0f; }
	//if( roughness >= 1.0f ){ roughness = 1.0f; }
	//if( KEY_Get( KEY_C ) ){ metalness += 0.003f; }
	//if( KEY_Get( KEY_D ) ){ metalness -= 0.003f; }
	//if( metalness <= .0f ){ metalness = .0f; }
	//if( metalness >= 1.0f ){ metalness = 1.0f; }

	m_obj -> SetScale( m_scale );
	m_obj -> SetAngle( m_angle );
	m_obj -> SetPos( m_pos );
	m_obj -> Update();
}

void Object::Render()
{
	m_obj -> Render();
}

void Object::Render( iexShader* shader, char* name )
{
	shader->SetValue("testMetalness", m_metalness );
	shader->SetValue("testRoughness", m_roughness );
	m_obj -> Render( shader, name );
}

void Object::Move()
{
	//スティック情報取得
	float AxisX =  KEY_GetAxisX() * 0.01f;
	float AxisY = -KEY_GetAxisY() * 0.01f;
	//軸補正
	if( AxisX*AxisX < 0.3f*0.3f ) AxisX = .0f;
	if( AxisY*AxisY < 0.3f*0.3f ) AxisY = .0f;
	
	//方向ベクトル
	Vector3 front( matView._13, 0, matView._33 );
	front.Normalize();
	Vector3 right( matView._11, 0, matView._31 );
	right.Normalize();
	//移動量
	m_move = ( front*AxisY + right*AxisX ) * SPEED;

	//左右判定
	float x1 = m_move.x; float z1 = m_move.z;
	float x2 = sinf( m_vec ); float z2 = cosf( m_vec );
	//外積
	float cross = x1*z2 - x2*z1;
	//補正量調整
	float d = sqrtf( x1*x1 + z1*z1 );
	float n = ( x1*x2 + z1*z2 ) / d;
	float adjust = ( 1-n ) * 2.0f;
	if( adjust > 0.3f ) adjust = 0.3f;

	//方向転換
	if( cross < 0 ) m_vec -= adjust;
	else m_vec += adjust;

	m_pos += m_move;
}