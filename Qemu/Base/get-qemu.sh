#!/bin/bash

ARCHIVE=$1
SOURCE=${2:-''}
MODE=${3:-'e'}

wget https://download.qemu.org/qemu-8.1.2.tar.xz

if [ $MODE = 'e' ]; then
    # x -> Extract
    # v -> Show extraction progress
    # J -> XZ decompression
    # f -> Archive name
    tar xvJf qemu-8.1.2.tar.xz
fi
