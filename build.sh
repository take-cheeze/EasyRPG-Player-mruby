#!/usr/bin/env bash

cd $(dirname $0)
SCRIPT_PATH=$(pwd)

if [ ! -d $SCRIPT_PATH/mruby ] ; then
		git clone --depth 1 https://github.com/EasyRPG/mruby.git $SCRIPT_PATH/mruby
fi

cd $SCRIPT_PATH/mruby

MRUBY_CONFIG=$SCRIPT_PATH/config.rb rake $@
