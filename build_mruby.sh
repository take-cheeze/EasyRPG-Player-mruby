#!/usr/bin/env bash -e

cd $(dirname $0)
SCRIPT_PATH=$(pwd)

if [ ! -d $SCRIPT_PATH/mruby ] ; then
		git clone --depth 1 git@github.com:EasyRPG/mruby.git $SCRIPT_PATH/mruby
fi

cd $SCRIPT_PATH/mruby

MRUBY_CONFIG=$SCRIPT_PATH/build_config.rb rake $@
