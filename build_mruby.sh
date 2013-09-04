#!/usr/bin/env bash -e

cd $(dirname $0)
SCRIPT_PATH=$(pwd)

if [ ! -d $SCRIPT_PATH/mruby ] ; then
		git clone git@github.com:mruby/mruby.git $SCRIPT_PATH/mruby
fi

MRUBY_CONFIG=$SCRIPT_PATH/build_config.rb make -C $SCRIPT_PATH/mruby $@
