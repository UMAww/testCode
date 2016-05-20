#include	"iextreme.h"
//#include	"system/system.h"
#include	"Object.h"

//-------------------------------------’è”éŒ¾‚Æ‚©---------------------------------------------------------

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