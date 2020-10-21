#!/bin/bash

#sudo apt-get install autogen autoconf libtool libeigen3-dev libhdf5-dev patchelf gfortran
echo $1


docker run -v "$PWD/../:/Trelis-plugin" -v "$2:/Trelis-sdk" -it $1 bash -c "/Trelis-plugin/script/build_plugin.sh $3"