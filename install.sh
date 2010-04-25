#!/bin/sh

#インストールフォルダ
INSTALL_FOLDER=/mnt/www/Pegasus

#フォルダ作成
mkdir ${INSTALL_FOLDER}
mkdir ${INSTALL_FOLDER}/admin
mkdir ${INSTALL_FOLDER}/skin
mkdir ${INSTALL_FOLDER}/module
mkdir ${INSTALL_FOLDER}/page
mkdir ${INSTALL_FOLDER}/file

#ファイルコピー
cp cms/index.rb ${INSTALL_FOLDER}/index.rb
cp cms/setting.rb ${INSTALL_FOLDER}/serring.rb
cp cms/admin/index.rb ${INSTALL_FOLDER}/admin/index.rb
cp cms/skin/* ${INSTALL_FOLDER}/skin/
cp cms/module/* ${INSTALL_FOLDER}/module/
cd ${INSTALL_FOLDER}/

chmod 705 . -R
chmod 666 count_log.rb
chmod 777 page/
chmod 666 page/*
chmod 777 files/
chmod 666 files/*
