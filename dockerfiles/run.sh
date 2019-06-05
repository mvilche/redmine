#!/bin/sh
set -e

APP_NAME=redmine
APP_ROOT=/opt/redmine
APP_DATADIR=/opt/redmine/.init
APP_VERSION=4.0.3
APP_REPO=https://github.com/redmine/redmine.git
APP_EXTRA_THEME=https://github.com/akabekobeko/redmine-theme-minimalflat2/releases/download/v1.6.0/minimalflat2-1.6.0.zip

export REDMINE_LANG=es
export RAILS_ENV=production


if [ ! -d $APP_ROOT ]; then
mkdir -p  $APP_ROOT
fi

    if [ -z $USER_ID ]; then
    echo "***************************************************"
    echo "NO SE ENCUENTRA LA VARIABLE USER_ID - INICIANDO POR DEFECTO"
    echo "*******************************************************"
    export USER_ID=redmine
    else
    echo "***************************************************"
    echo "VARIABLE USER_ID ENCONTRADA SETEANADO VALORES: $USER_ID"
    usermod -u $USER_ID redmine
    groupmod -g $USER_ID redmine
    echo "*******************************************************"
    fi


if [ -z "$TIMEZONE" ]; then
echo "···································································································"
echo "VARIABLE TIMEZONE NO SETEADA - INICIANDO CON VALORES POR DEFECTO"
echo "POSIBLES VALORES: America/Montevideo | America/El_Salvador"
echo "···································································································"
else
echo "···································································································"
echo "TIMEZONE SETEADO ENCONTRADO: " $TIMEZONE
echo "···································································································"
echo "SETENADO TIMEZONE"
cat /usr/share/zoneinfo/$TIMEZONE > /etc/localtime && \
echo $TIMEZONE > /etc/timezone
fi







    if [ -z $DATABASE_HOST ] || [ -z $DATABASE_USER ] || [ -z $DATABASE_PASSWORD ] || [ -z $DATABASE_NAME ]; then
    echo "***************************************************"
    echo "SE DETECTARON VARIABLES REQUERIDAS NO SETEADAS, VERIFICAR DATABASE_USER, DATABASE_PASSWORD, DATABASE_HOST, DATABASE_NAME"
    echo "*******************************************************"
    exit 1
    fi


if [ -d $APP_DATADIR ]; then
	echo "**********************************************"
    echo "APP YA FUE INICIALIZADA - SE ENCONTRARON DATOS"
    echo "**********************************************"
else

    echo "***************************************************"
    echo "APP NO SE HA INICIALIZADO"
    echo "LA APLICACION DESCARGARA E INSTALARA TODO LO NECESARIO PARA COMENZAR"
    echo "EL TIEMPO DE LA DESCARGA E INSTALACION DE LAS DEPENDENCIAS SERA DE UNOS MINUTOS"
    echo "INICIALIZANDO..."
    echo "*******************************************************"


cd $APP_ROOT && echo "CLONANDO REPO...."
git clone --depth=1 -b $APP_VERSION $APP_REPO .
curl -Lo theme.zip $APP_EXTRA_THEME
unzip theme.zip -d $APP_ROOT/public/themes/
rm theme.zip

cat << EOF > config/database.yml
production:
  adapter: mysql2
  database: ${DATABASE_NAME}
  host: ${DATABASE_HOST}
  username: ${DATABASE_USER}
  password: "${DATABASE_PASSWORD}"
  encoding: utf8
EOF
mv config/configuration.yml.example config/configuration.yml
rm config/database.yml.example
echo "INSTALANDO DEPENDENCIAS...."
bundle install --without development test rmagick --path install_lib
echo "FIN INSTALACION DEPENDENCIAS"

echo "INICIANDO MIGRACION DE DATOS....."
bundle exec rake generate_secret_token
RAILS_ENV=production bundle exec rake db:migrate
RAILS_ENV=production bundle exec rake redmine:load_default_data
mkdir -p $APP_DATADIR
    echo "FIX PERMISOS.." && chown $USER_ID:$USER_ID -R $APP_ROOT && cd $APP_ROOT
    echo "*******************************************************"
echo "APP $APP_NAME $APP_VERSION INICIALIZADO CORRECTAMENTE"
    echo "*******************************************************"
echo "TAREAS COMPLETADAS CORRECTAMENTE."
echo "CONFIGURE EL ARCHIVO $APP_ROOT/config/configuration.yml CON LOS VALORES DESEADOS"
    echo "*******************************************************"
fi

chown $USER_ID:$USER_ID -R $APP_ROOT && echo "FIX PERMISSION OK"
rm -rf /opt/redmine/tmp/pids/* &> /dev/null
echo "INICIANDO $APP_NAME...."
sleep 5s
exec su-exec $USER_ID bundle exec rails server "$@"
