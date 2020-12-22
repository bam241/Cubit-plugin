#!/bin/bash

#curl https://distfiles.macports.org/MacPorts/MacPorts-2.6.3-10.15-Catalina.pkg --output MacPorts-2.6.3-10.15-Catalina.pkg


#sudo installer -pkg MacPorts-2.6.3-10.15-Catalina.pkg -target /

export PATH=/opt/local/bin:/opt/local/sbin:$PATH
export MANPATH=/opt/local/share/man:$MANPATH
export LD_LIBRARY_PATH=/opt/local/lib:$LD_LIBRARY_PATH


#sudo port selfupdate
#sudo port install autogen autoconf libtool eigen3 hdf5 patchelf cmake gcc6 wget realpath

#wget https://github.com/fxcoudert/gfortran-for-macOS/releases/download/10.2/gfortran-10.2-Catalina.dmg
#hdiutil attach gfortran-10.2-Catalina.dmg
#sudo installer -pkg /Volumes/gfortran-10.2-Catalina/gfortran.pkg -target /
#hdiutil detach /Volumes/gfortran-10.2-Catalina



cd 

# Setup
CURRENT=$(pwd)
SCRIPTPATH=`dirname $(dirname $(realpath $0))`

PLUGIN_DIR="plugin-build"

mkdir ${PLUGIN_DIR}
PLUGIN_ABS_PATH=${CURRENT}/${PLUGIN_DIR}

echo "Building the Trelis plugin in ${CURRENT}\\${PLUGIN_DIR}"

unset LD_LIBRARY_PATH

cd ${PLUGIN_ABS_PATH}
ln -s $SCRIPTPATH/ ./

mkdir -pv moab/bld
cd moab
git clone https://bitbucket.org/fathomteam/moab -b Version5.1.0
cd moab
autoreconf -fi
cd ../bld
../moab/configure --disable-blaslapack \
                  --enable-shared \
		  --enable-optimize \
                  --disable-debug \
                  --disable-blaslapack \
                  --with-eigen3=/opt/local/include/eigen3 \
                  --with-hdf5=/opt/local/ \
                  --prefix=${PLUGIN_ABS_PATH}/moab
make -j`grep -c processor /proc/cpuinfo`
make install

cd ${PLUGIN_ABS_PATH}
mkdir -pv DAGMC/bld
cd DAGMC
git clone https://github.com/svalinn/DAGMC -b develop
cd bld
cmake ../DAGMC -DMOAB_DIR=${PLUGIN_ABS_PATH}/moab \
               -DBUILD_UWUW=ON \
               -DBUILD_TALLY=OFF \
               -DBUILD_BUILD_OBB=OFF \
               -DBUILD_MAKE_WATERTIGHT=ON \
               -DBUILD_SHARED_LIBS=ON \
               -DBUILD_STATIC_LIBS=OFF \
               -DBUILD_STATIC_EXE=OFF \
	       -DCMAKE_BUILD_TYPE=Release \
               -DCMAKE_INSTALL_PREFIX=${PLUGIN_ABS_PATH}/DAGMC
make -j`grep -c processor /proc/cpuinfo`
make install



cd /Applications/Trelis-17.1.app/Contents 
tar -xzf /Users/mouginot/SDK/Trelis-SDK-17.1.0-Mac64.tar .
cp -rf bin/* MacOS/
rm -rf bin
ln -s MacOS bin
cd bin
sudo cp -pv CubitExport-Release.cmake CubitExport-Release.cmake.orig
#sudo port install gsed
sudo gsed -i "s/\"Trelis-17.1.app\/Contents/\MacOS\"/\"bin\"/" CubitExport-Release.cmake
cd 

cd ${PLUGIN_ABS_PATH}/Trelis-plugin
git submodule update --init

cd ${PLUGIN_ABS_PATH}
rm -rf bld
mkdir -pv bld
cd bld
cmake ../Trelis-plugin -DCMAKE_PREFIX_PATH=/Applications/Trelis-17.1.app/Contents/bin \
		       -DCUBIT_ROOT=/Applications/Trelis-17.1.app/Contents/bin \
                       -DDAGMC_DIR=${PLUGIN_ABS_PATH}/DAGMC \
		       -DCMAKE_INSTALL_PREFIX=${PLUGIN_ABS_PATH}
make
make install


#                       -DCMAKE_BUILD_TYPE=Release \



cd ${PLUGIN_ABS_PATH}
mkdir -p pack/bin/plugins/svalinn
cd pack/bin/plugins/svalinn

# Copy all needed libraries into current directory
cp -pPv ${PLUGIN_ABS_PATH}/lib/* .
cp -pPv ${PLUGIN_ABS_PATH}/moab/lib/libMOAB.dylib .
cp -pPv ${PLUGIN_ABS_PATH}/DAGMC/lib/libdagmc.dylib .
cp -pPv ${PLUGIN_ABS_PATH}/DAGMC/lib/libmakeWatertight.dylib .
cp -pPv ${PLUGIN_ABS_PATH}/DAGMC/lib/libpyne_dagmc.dylib .
cp -pPv ${PLUGIN_ABS_PATH}/DAGMC/lib/libuwuw.dylib .
cp -pPv /opt/local/lib/libhdf5.*.dylib .
chmod 644 *

# # Set the RPATH to be the current directory for the DAGMC libraries
install_name_tool -change /Users/mouginot/plugin-build/moab/lib/libMOAB.0.dylib


install_name_tool -add_rpath /Applications/Trelies-17.1.app/Contents/bin/plugins/svalinn libdagmc.dylib
install_name_tool -add_rpath /Applications/Trelies-17.1.app/Contents/bin/plugins/svalinn libmakeWatertight.dylib
install_name_tool -add_rpath /Applications/Trelies-17.1.app/Contents/bin/plugins/svalinn libpyne_dagmc.dylib
install_name_tool -add_rpath /Applications/Trelies-17.1.app/Contents/bin/plugins/svalinn libuwuw.dylib

# Create the Svalinn plugin tarball
cd ..
ln -sv svalinn/libsvalinn_plugin.so .
cd ../..
tar -czvf svalinn-plugin_mac.tgz bin
mv -v svalinn-plugin_mac.tgz ~/
cd ..
# rm -rf pack bld DAGMC lib moab
# rm Trelis-plugin
