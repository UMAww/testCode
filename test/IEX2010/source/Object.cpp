#include	"iextreme.h"
#include	"system/system.h"
#include	"Object.h"

//-------------------------------------定数宣言とか---------------------------------------------------------

const float Object::SPEED = 0.01f;

//------------------------------------------------------------------------------------------------------------

Object::Object() : obj( nullptr ), move( .0f, .0f, .0f ), vec( .0f ), metalness(1.0f), roughness( 0.0f )
{
}

Object::Object( char* filename ) : obj( nullptr ), move( .0f, .0f, .0f ), vec( .0f ), metalness(1.0f), roughness( 0.0f )
{
	obj = new iexMesh( filename );
	this->pos = this->angle = Vector3( .0f, .0f, .0f );
	this->scale = Vector3( 1.0f, 1.0f, 1.0f );
	obj->SetScale( this->scale );
	obj->SetAngle( this->angle );
	obj->SetPos( this->pos );
	obj->Update();
}

Object::Object( char* filename, Vector3 pos, Vector3 angle, Vector3 scale ) : obj( nullptr ), move( .0f, .0f, .0f ), vec( .0f ), metalness(1.0f), roughness( 0.0f )
{
	obj = new iexMesh( filename );
	this->pos = pos;
	this->angle = angle;
	this->scale = scale;
	obj->SetScale( this->scale );
	obj->SetAngle( this->angle );
	obj->SetPos( this->pos );
	obj->Update();
}

Object::~Object()
{
	if( obj ){ delete obj; obj = nullptr; }
}

void Object::Init( char* filename )
{
	obj = new iexMesh( filename );
}

void Object::Update()
{
	//移動
	Move();

	//angle.y += 0.01f;
	if( KEY_Get( KEY_A ) ){ roughness += 0.003f; }
	if( KEY_Get( KEY_B ) ){ roughness -= 0.003f; }
	if( roughness <= .0f ){ roughness = .0f; }
	if( roughness >= 1.0f ){ roughness = 1.0f; }
	if( KEY_Get( KEY_C ) ){ metalness += 0.003f; }
	if( KEY_Get( KEY_D ) ){ metalness -= 0.003f; }
	if( metalness <= .0f ){ metalness = .0f; }
	if( metalness >= 1.0f ){ metalness = 1.0f; }

	obj -> SetScale( scale );
	obj -> SetAngle( angle );
	obj -> SetPos( pos );
	obj -> Update();
}

void Object::Render()
{
	obj -> Render();
}

void Object::Render( char* name )
{
	shader->SetValue("Metalness", metalness );
	shader->SetValue("Roughness", roughness );
	obj -> Render( shader, name );
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
	move = ( front*AxisY + right*AxisX ) * SPEED;

	//左右判定
	float x1 = move.x; float z1 = move.z;
	float x2 = sinf( vec ); float z2 = cosf( vec );
	//外積
	float cross = x1*z2 - x2*z1;
	//補正量調整
	float d = sqrtf( x1*x1 + z1*z1 );
	float n = ( x1*x2 + z1*z2 ) / d;
	float adjust = ( 1-n ) * 2.0f;
	if( adjust > 0.3f ) adjust = 0.3f;

	//方向転換
	if( cross < 0 ) vec -= adjust;
	else vec += adjust;

	pos += move;
}