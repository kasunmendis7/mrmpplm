#!/bin/bash

CONFIGURE=${1:-"nc"}

if [ "$CONFIGURE" = "c" ]
then
	./configure
fi

make -j 30
make install -j 30
