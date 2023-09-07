fx_version 'cerulean'
game 'gta5'

ui_page "html/index.html"

use_experimental_fxv2_oal 'yes'
lua54 'yes'

client_scripts {
    '@salty_tokenizer/init.lua',
    '@qb-garages/SharedConfig.lua',
    '@qb-apartments/config.lua',
    'config.lua',
    'client/main.lua',
    'client/npctaxi.lua',
}

server_scripts {
    --'@oxmysql/lib/MySQL.lua',
    '@salty_tokenizer/init.lua',
    '@mongodb/lib/MongoDB.lua',
    '@qb-garages/SharedConfig.lua',
    '@qb-apartments/config.lua',
    'config.lua',
    'server/main.lua',
}

shared_scripts {
	'@ox_lib/init.lua'
}

files {
    'html/*.html',
    'html/js/*.js',
    'html/img/*.png',
    'html/img/*.jpg',
    'html/img/*.webp',
    'html/css/*.css',
    'html/fonts/*.ttf',
    'html/fonts/*.otf',
    'html/fonts/*.woff',
    'html/img/backgrounds/*.png',
    'html/img/apps/*.png',
    'html/img/apps/*.webp',
    --'html/img/apps/silkroad/*.png',
}