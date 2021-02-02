#!/bin/bash



function install_prerequise() {
    TZ=America/Chicago
    sudo ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
    sudo apt-get update -y
    sudo apt-get install -y g++ libtool libeigen3-dev libhdf5-dev patchelf git cmake
}

function setup_folder() {
    cd ${CURRENT}
    mkdir ${PLUGIN_DIR}
    echo "Building the Trelis plugin in ${CURRENT}\\${PLUGIN_DIR}"

    unset LD_LIBRARY_PATH

    cd ${PLUGIN_DIR}
    PLUGIN_ABS_PATH=$(pwd)
    ln -s $SCRIPTPATH/ ./
}

function build_moab() {
    cd ${PLUGIN_ABS_PATH}
    mkdir -pv moab/bld
    cd moab
    git clone https://bitbucket.org/fathomteam/moab -b Version5.1.0
    cd bld
    cmake ../moab -DENABLE_HDF5=ON \
            -DCMAKE_PREFIX_PATH=/usr/lib/x86_64-linux-gnu/hdf5/serial \
            -DBUILD_SHARED_LIBS=ON \
            -DENABLE_BLASLAPACK=OFF \
            -DENABLE_FORTRAN=OFF \
            -DCMAKE_CXX_FLAGS=-D_GLIBCXX_USE_CXX11_ABI=0 \
            -DCMAKE_INSTALL_PREFIX=${PLUGIN_ABS_PATH}/moab

    make -j`grep -c processor /proc/cpuinfo`
    make install
    cd ../..
    rm -rf moab/moab moab/bld
}


function build_dagmc(){
    cd ${PLUGIN_ABS_PATH}
    mkdir -pv DAGMC/bld
    cd DAGMC
    git clone https://github.com/bam241/DAGMC -b build_exe
    cd bld
    cmake ../DAGMC -DCMAKE_CXX_FLAGS=-D_GLIBCXX_USE_CXX11_ABI=0 \
                -DMOAB_DIR=${PLUGIN_ABS_PATH}/moab \
                -DBUILD_UWUW=ON \
                -DBUILD_TALLY=OFF \
                -DBUILD_BUILD_OBB=OFF \
                -DBUILD_MAKE_WATERTIGHT=ON \
                -DBUILD_SHARED_LIBS=ON \
                -DBUILD_STATIC_LIBS=OFF \
                -DBUILD_EXE=OFF \
                -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
                -DCMAKE_BUILD_TYPE=Release \
                -DCMAKE_INSTALL_PREFIX=${PLUGIN_ABS_PATH}/DAGMC
    make -j`grep -c processor /proc/cpuinfo`
    make install
    cd ../..
    rm -rf DAGMC/DAGMC DAGCM/bld
}

function setup_Trelis_sdk() {
    cd $PKG_PATH 
    dpkg -i Trelis-$1-Lin64.deb

    cd /opt
    tar -xzvf /Trelis-sdk/Trelis-SDK-$1-Lin64.tar.gz
    cd /opt/Trelis-16.5
    tar -xzvf /Trelis-sdk/Trelis-SDK-$1-Lin64.tar.gz
}

function build_plugin(){
    cd ${PLUGIN_ABS_PATH}
    cd Trelis-plugin
    git submodule update --init
    cd ../
    mkdir -pv bld
    cd bld
    cmake ../Trelis-plugin -DCUBIT_ROOT=/opt/Trelis-${1::4} \
                           -DDAGMC_DIR=${PLUGIN_ABS_PATH}/DAGMC \
                           -DCMAKE_BUILD_TYPE=Release \
                           -DCMAKE_INSTALL_PREFIX=${PLUGIN_ABS_PATH}
    make -j`grep -c processor /proc/cpuinfo`
    make install
}

function build_plugin_pkg(){
    cd ${PLUGIN_ABS_PATH}
    mkdir -p pack/bin/plugins/svalinn
    cd pack/bin/plugins/svalinn

    # Copy all needed libraries into current directory
    cp -pPv ${PLUGIN_ABS_PATH}/lib/* .
    cp -pPv ${PLUGIN_ABS_PATH}/moab/lib/libMOAB.so* .
    cp -pPv ${PLUGIN_ABS_PATH}/DAGMC/lib/libdagmc.so* .
    cp -pPv ${PLUGIN_ABS_PATH}/DAGMC/lib/libmakeWatertight.so* .
    cp -pPv ${PLUGIN_ABS_PATH}/DAGMC/lib/libpyne_dagmc.so* .
    cp -pPv ${PLUGIN_ABS_PATH}/DAGMC/lib/libuwuw.so* .
    cp -pPv /usr/lib/x86_64-linux-gnu/libhdf5_serial.so* .
    chmod 644 *

    # Set the RPATH to be the current directory for the DAGMC libraries
    patchelf --set-rpath /opt/Trelis-${1::4}/bin/plugins/svalinn libMOAB.so
    patchelf --set-rpath /opt/Trelis-${1::4}/bin/plugins/svalinn libdagmc.so
    patchelf --set-rpath /opt/Trelis-${1::4}/bin/plugins/svalinn libmakeWatertight.so
    patchelf --set-rpath /opt/Trelis-${1::4}/bin/plugins/svalinn libpyne_dagmc.so
    patchelf --set-rpath /opt/Trelis-${1::4}/bin/plugins/svalinn libuwuw.so

    # Create the Svalinn plugin tarball
    cd ..
    ln -sv svalinn/libsvalinn_plugin.so .
    cd ../..
    tar --sort=name -czvf svalinn-plugin_linux_$1.tgz bin
}