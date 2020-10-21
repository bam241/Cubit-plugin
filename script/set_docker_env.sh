#!/bin/bash

echo $0
SCRIPTPATH=`dirname $(dirname $(realpath $0))`
echo $SCRIPTPATH
docker run -v "$SCRIPTPATH:/Trelis-plugin" -v "$2:/Trelis-sdk" -it $1 bash -c "ls /Trelis-plugin/script"
docker run -v "$SCRIPTPATH:/Trelis-plugin" -v "$2:/Trelis-sdk" -it $1 bash -c "/Trelis-plugin/script/build_plugin.sh $3"