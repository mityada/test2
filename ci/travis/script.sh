#!/bin/bash -ex

if [ "$TRAVIS_OS_NAME" = 'osx' ]; then
    export PYTHONPATH=$PYTHONPATH:/usr/local/lib/python2.7/site-packages
fi

function install_cuda_linux()
{
    wget https://developer.nvidia.com/compute/cuda/8.0/Prod2/local_installers/cuda-repo-ubuntu1404-8-0-local-ga2_8.0.61-1_amd64-deb -O cuda-repo-ubuntu1404-8-0-local-ga2_8.0.61-1_amd64.deb
    sudo dpkg -i cuda-repo-ubuntu1404-8-0-local-ga2_8.0.61-1_amd64.deb
    sudo apt-get update
    sudo apt-get install cuda    
}

function install_cuda_darwin()
{
    if [ -f $HOME/.ya/cuda_8.0.61_mac.dmg ]; then
        rm $HOME/.ya/cuda_8.0.61_mac.dmg
    fi
    if [ $(openssl dgst -md5 -hex $HOME/.ya/cuda_9.0.176_mac.dmg | awk '{print $2;}') != 19369a391a7475cace0f3c377aebbecb ]; then
        rm $HOME/.ya/cuda_9.0.176_mac.dmg
    fi
    
    if [ ! -f $HOME/.ya/cuda_9.0.176_mac.dmg ]; then
        wget https://developer.nvidia.com/compute/cuda/9.0/Prod/local_installers/cuda_9.0.176_mac-dmg -c -O cuda_9.0.176_mac.dmg
        if [ $(openssl dgst -md5 -hex cuda_9.0.176_mac.dmg | awk '{print $2;}') == 19369a391a7475cace0f3c377aebbecb ]; then
           mv cuda_9.0.176_mac.dmg $HOME/.ya/cuda_9.0.176_mac.dmg
        else
           exit 1
        fi
    fi
    hdiutil attach $HOME/.ya/cuda_9.0.176_mac.dmg
    sudo /Volumes/CUDAMacOSXInstaller//CUDAMacOSXInstaller.app/Contents/MacOS/CUDAMacOSXInstaller --accept-eula --no-window
    # exit 0  # XXX
}

if [ "${CB_BUILD_AGENT}" == 'clang-linux-x86_64-release-cuda' ]; then
    install_cuda_linux;
    ./ya make --no-emit-status --stat -T -r -j 1 catboost/app -DCUDA_ROOT=/usr/local/cuda-8.0;
    cp $(readlink -f catboost/app/catboost) catboost-cuda-linux;
    python ci/webdav_upload.py catboost-cuda-linux
fi

if [ "${CB_BUILD_AGENT}" == 'python2-linux-x86_64-release' ]; then
     install_cuda_linux;
     cd catboost/python-package;
     python2 ./mk_wheel.py --no-emit-status -T -j 1 -DCUDA_ROOT=/usr/local/cuda-8.0 ;
     python ../../ci/webdav_upload.py *.whl
fi

if [ "${CB_BUILD_AGENT}" == 'python35-linux-x86_64-release' ]; then
     ln -s /home/travis/virtualenv/python3.5.4/bin/python-config /home/travis/virtualenv/python3.5.4/bin/python3-config;
     install_cuda_linux;
     cd catboost/python-package;
     python3 ./mk_wheel.py --no-emit-status -T -j 1 -DCUDA_ROOT=/usr/local/cuda-8.0 -DPYTHON_CONFIG=/home/travis/virtualenv/python3.5.4/bin/python3-config;
     python ../../ci/webdav_upload.py *.whl
fi

if [ "${CB_BUILD_AGENT}" == 'python36-linux-x86_64-release' ]; then
     ln -s /home/travis/virtualenv/python3.6.3/bin/python-config /home/travis/virtualenv/python3.6.3/bin/python3-config;
     install_cuda_linux;
     cd catboost/python-package;
     python3 ./mk_wheel.py --no-emit-status -T -j 1 -DCUDA_ROOT=/usr/local/cuda-8.0 -DPYTHON_CONFIG=/home/travis/virtualenv/python3.6.3/bin/python3-config;
     python ../../ci/webdav_upload.py *.whl
fi

if [ "${CB_BUILD_AGENT}" == 'clang-darwin-x86_64-release' ]; then
    ./ya make --no-emit-status --stat -T -r -j 1 catboost/app;
    cp $(readlink catboost/app/catboost) catboost-darwin;
    python ci/webdav_upload.py catboost-darwin
fi

if [ "${CB_BUILD_AGENT}" == 'clang-darwin-x86_64-release-cuda' ]; then
    install_cuda_darwin;
    ./ya make --stat -T -r -j 2 catboost/cuda/app -DCUDA_ROOT=/usr/local/cuda;
    cp $(readlink catboost/cuda/app/catboost) catboost-cuda-darwin;
    python ../../ci/webdav_upload.py catboost-cuda-darwin;
fi

if [ "${CB_BUILD_AGENT}" == 'python-darwin-x86_64-release' ]; then
    install_cuda_darwin;
    cd catboost/python-package;
    python2.7 ./mk_wheel.py -T -DCUDA_ROOT=/usr/local/cuda;
    pyenv install 3.5.2;
    $HOME/.pyenv/versions/3.5.2/bin/python3.5 ./mk_wheel.py -T -DCUDA_ROOT=/usr/local/cuda -DPYTHON_CONFIG=$HOME/.pyenv/versions/3.5.2/bin/python3-config;
    pyenv install 3.6.3;
    $HOME/.pyenv/versions/3.6.3/bin/python3.6 ./mk_wheel.py -T -DCUDA_ROOT=/usr/local/cuda -DPYTHON_CONFIG=$HOME/.pyenv/versions/3.6.3/bin/python3-config;
    python ../../ci/webdav_upload.py *.whl;
fi

if [ "${CB_BUILD_AGENT}" == 'R-clang-darwin-x86_64-release' ] || [ "${CB_BUILD_AGENT}" == 'R-clang-linux-x86_64-release' ]; then
    cd catboost/R-package

    mkdir catboost

    cp DESCRIPTION catboost
    cp NAMESPACE catboost
    cp README.md catboost

    cp -r R catboost

    cp -r inst catboost
    cp -r man catboost
    cp -r tests catboost

    ../../ya make -r -T src

    mkdir catboost/inst/libs
    cp $(readlink src/libcatboostr.so) catboost/inst/libs

    tar -cvzf catboost-R-$(uname).tgz catboost
    python ../../ci/webdav_upload.py catboost-R-*.tgz
fi

