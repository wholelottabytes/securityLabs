#!/bin/bash
set -e

PROJECT_NAME="HashLibrary"
BUILD_DIR="build"
INSTALL_DIR="install"

rm -rf $BUILD_DIR $INSTALL_DIR

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

build_for_arch() {
    local ARCH=$1
    local TOOLCHAIN=$2
    local CMAKE_ARGS=$3
    
    echo -e "${YELLOW}Сборка для архитектуры: $ARCH${NC}"
    
    BUILD_ARCH_DIR="$BUILD_DIR/$ARCH"
    INSTALL_ARCH_DIR="$INSTALL_DIR/$ARCH"
    
    mkdir -p $BUILD_ARCH_DIR $INSTALL_ARCH_DIR
    cd $BUILD_ARCH_DIR
    
    cmake ../../ \
        -DCMAKE_INSTALL_PREFIX=../../$INSTALL_ARCH_DIR \
        -DCMAKE_BUILD_TYPE=Release \
        $CMAKE_ARGS $TOOLCHAIN
    
    make -j$(nproc) && make install
    cd ../../
    
    echo -e "${GREEN}✓ Сборка для $ARCH завершена${NC}"
}

# Основная сборка для Linux x86_64
build_for_arch "linux-x86_64" "" ""

# Windows сборка (если MinGW доступен)
if command -v x86_64-w64-mingw32-gcc >/dev/null 2>&1; then
    sudo apt install -y mingw-w64 2>/dev/null || true
    if [ -f "toolchains/toolchain-mingw-w64-x86_64.cmake" ]; then
        build_for_arch "windows-x86_64" "-DCMAKE_TOOLCHAIN_FILE=../../toolchains/toolchain-mingw-w64-x86_64.cmake" ""
    fi
fi

echo -e "${GREEN}Сборка завершена! Результаты в: $INSTALL_DIR${NC}"