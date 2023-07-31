# 前提ライブラリ
# brew install gnu-sed
# --自分の環境に合わせて設定してください--
PROJECT_DIR="/Applications/XAMPP/xamppfiles/htdocs/"
DB_USER="root"
DB_PASSWORD="" #パスワード設定未対応
DEFAULT_LARAVEL_VER="8.*"
MYSQL_DIR="/Applications/XAMPP/bin/mysql"
# --環境ごとの設定ここまで--

# プロジェクト、ディレクトリ名
unset $PROJECT_NAME
while [ -z $PROJECT_NAME ]
do
	echo "Project Name?(required)"
	read PROJECT_NAME
done
echo $PROJECT_NAME

# データベース名
unset $DB_NAME
while [ -z $DB_NAME ]
do
	echo "Database Name?(required)"
	read DB_NAME
done
echo $DB_NAME

# Laravel バージョン
echo "laravel ver?(Default: ${DEFAULT_LARAVEL_VER})"
read LARAVEL_VER;
echo "${LARAVEL_VER:=${DEFAULT_LARAVEL_VER}}"

# Laravel-adminをインストールするか
echo "need laravel-admin?(y/n)"
read IS_INSTALL_LARAVELADMIN;
echo "${IS_INSTALL_LARAVELADMIN:="y"}"

PHP_VER=""
PROJECT_PATH=${PROJECT_DIR}${PROJECT_NAME}

# DB作成 【なぜかパスワードありだとうまくログインできない】
/Applications/XAMPP/bin/mysql -uroot -e "CREATE DATABASE $DB_NAME DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"

# unset dbpassinput
# if [ -n "$dbpass" ]; then
# 	dbpassinput="-p ${dbpass}"
# fi
# createdbquery="CREATE DATABASE ${DB_NAME} DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
# $MYSQL_DIR -u ${dbuser} ${dbpassinput} -e ${createdbquery}

# ディレクトリの作成と移動
mkdir $PROJECT_PATH
cd $PROJECT_PATH

# Laravelの設置とパーミッション設定
composer create-project --prefer-dist laravel/laravel . "${LARAVEL_VER}"

chmod -R 0777 ${PROJECT_PATH}/storage
chmod -R 0777 ${PROJECT_PATH}/bootstrap/cache
git init
git add .
git commit -m"Laravel install"

# Laravelのconfig書き換え
gsed -i "s|'timezone' => 'UTC',|'timezone' => 'Asia/Tokyo',|" config/app.php
gsed -i "s|'locale' => '.*',|'locale' => 'ja',|" config/app.php
gsed -i "s|'days' => 14,|'days' => 180,|" config/logging.php
gsed -i "s|// protected $namespace|protected $namespace|" app/Providers/RouteServiceProvider.php
git add .
git commit -m"Set locale and route configs"

# Laravel .envファイルの書き換え
gsed -i "s|APP_URL=.*|APP_URL=http://localhost:8000|" .env
gsed -i "s|DB_DATABASE=.*|DB_DATABASE=$DB_NAME|" .env
gsed -i "s|DB_USERNAME=.*|DB_USERNAME=$DB_USER|" .env
gsed -i "s|DB_PASSWORD=.*|DB_PASSWORD=$DB_PASSWORD|" .env
gsed -i "s|LOG_CHANNEL=stack|LOG_CHANNEL=daily|" .env

gsed -i '$ a\\' .env
gsed -i "$ aBASICAUTH_USER=\"alpha\"" .env
gsed -i "$ aBASICAUTH_PASSWORD=\"Ky9g6DMtZ;\"" .env
gsed -i "$ aBASICAUTH_TO_AT=\"2022-12-03 23:59:59\"" .env
gsed -i '$ a\\' .env
gsed -i "$ aIP_RESTRICTION_ALLOW_IPS=::1,127.0.0.1,202.214.242.193" .env
gsed -i "$ aIP_RESTRICTION_TO_AT=\"2022-12-03 23:59:59\"" .env
# アップロードディレクトリへのシンボリックリンクの作成
php artisan storage:link

# composerのライブラリ管理の基準となるPHPバージョンの設定
if [ -n "$PHP_VER" ]; then
	composer config platform.php $PHP_VER
	git add .
	git commit -m"set php version"
fi

# 翻訳ファイルの設置
composer require kitamula/laravel-language-setting
php artisan lang:setting ja
git add .
git commit -m"add language ja"

# BladeのPublish
php artisan vendor:publish --tag=laravel-pagination
git add .
git commit -m"Publish Blade - Pagination"
if [ $IS_INSTALL_LARAVELADMIN = "y" ]; then
	# laravel-admin
	composer require kitamula/laravel-admin
	php artisan vendor:publish --provider="Encore\Admin\AdminServiceProvider"

	php artisan admin:install
	mkdir resources/views/laravel-admin
	cp -rf vendor/kitamula/laravel-admin/resources/views/* resources/views/laravel-admin/
	gsed -i "$ aapp('view')->prependNamespace('admin',resource_path('views/laravel-admin'));" app/Admin/bootstrap.php
	git add .
	git commit -m"Laravel-admin"
	# viewファイルのオーバーライド


	# Sortable
	composer require laravel-admin-ext/grid-sortable -vvv
	php artisan vendor:publish --provider="Encore\Admin\GridSortable\GridSortableServiceProvider"
	git add .
	git commit -m"Laravel-admin Sortable"
fi

composer require doctrine/dbal:^2.6
git add .
git commit -m"require doctrine/dbal:^2.6"

composer require intervention/image
git add .
git commit -m"require intervention/image"

# 自社パッケージ
composer require kitamula/kitchen
php artisan vendor:publish --provider="Kitamula\Kitchen\KitchenServiceProvider"
git add .
git commit -m"add kitchen"

# SourceTreeへの登録
# stree `PWD`
# vscodeで開く
code .
