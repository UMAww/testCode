#include"iextreme.h"
#include"system\System.h"
#include"ObjectManager.h"

iexMesh* ObjectManager::m_model;
Object* ObjectManager::m_obj[MAX_NUM];

ObjectManager::ObjectManager( char* filename )
{
	m_model = new iexMesh( filename );
	for( int i = 0; i < MAX_NUM; i++ )
	{
		m_obj[i] = new Object( m_model );
		m_obj[i]->SetScale( 0.01f );
	}
	//‚Æ‚è‚ ‚¦‚¸•À‚×‚é
	float pos_y = 2.0f;
	const float minX = -10.0f;
	const float minZ = -10.0f;
	for( int x = 0; x < static_cast<int>(MAX_NUM/COLUMN_NUM); x++ )
	{
		float pos_x = minX + static_cast<float>( x ) * 2.0f;
		for( int z = 0; z < static_cast<int>(MAX_NUM/COLUMN_NUM); z++ )
		{
			float pos_z = minZ + static_cast<float>( z ) * 2.0f;
			int index = COLUMN_NUM*x + z;
			m_obj[index]->SetPos( Vector3( pos_x, pos_y, pos_z ) );
			//‰¡—ñ¨Roughness
			m_obj[index]->SetRoughness( static_cast<float>( x/10.0f ) );
			//c—ñ¨Metalness
			m_obj[index]->SetMetalness( static_cast<float>( z/10.0f ) );
		}
	}
}

ObjectManager::~ObjectManager()
{
	if( m_model ){ delete m_model; m_model = nullptr; }
	for( int i = 0; i < MAX_NUM; i++ )
	{
		if( m_obj[i] )
		{
			delete m_obj[i];
			m_obj[i] = nullptr;
		}
	}
}

void ObjectManager::Update()
{
	for( int i = 0; i < MAX_NUM; i++ )
	{
		if( !m_obj[i]->m_isEnable ) continue;
		m_obj[i]->Update();
	}
}

void ObjectManager::Render()
{
	for( int i = 0; i < MAX_NUM; i++ )
	{
		if( !m_obj[i]->m_isEnable ) continue;
		m_obj[i]->Render();
	}
}

void ObjectManager::Render( char* pass )
{
	for( int i = 0; i < MAX_NUM; i++ )
	{
		if( !m_obj[i]->m_isEnable ) continue;
		m_obj[i]->Render(shader, pass);
	}
}