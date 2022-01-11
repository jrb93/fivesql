fx_version 'cerulean'
game 'common'

name 'fivesql'
description 'MySQL wrapper for FiveM using oxmysql, allowing easy query building'
author 'Wolfy'
version '1.0.0'
url 'https://github.com/jrb93/fivesql'

server_script {
	'@oxmysql/lib/MySQL.lua',
	'sv_fivesql.lua'
}

dependencies {
	'oxmysql'
}

convar_category 'MySQL' {
	nil,
	{
		{ "MySQL connection string", "mysql_connection_string", "CV_STRING", "" }
	}
}