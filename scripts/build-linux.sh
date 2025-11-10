#!/usr/bin/env bash
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 <arch>  # arch = x86_64 or x86"
  exit 1
fi

ARCH="$1"
ROOT="$(pwd)"
BUILD_DIR="${ROOT}/build-${ARCH}"
INSTALL_DIR="${ROOT}/install-${ARCH}"
STAGING_DIR="${ROOT}/staging-${ARCH}"

mkdir -p "${BUILD_DIR}" "${INSTALL_DIR}" "${STAGING_DIR}"
cd "${BUILD_DIR}"

if [ "${ARCH}" = "x86_64" ]; then
  cmake -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}" \
        -DLIBUNWIND_ENABLE_SHARED=ON \
        -DLIBUNWIND_ENABLE_STATIC=ON \
        "${ROOT}"
else
  # Build 32-bit (x86) on x86_64 runner using multilib flags
  export CFLAGS="-m32"
  export CXXFLAGS="-m32"
  export LDFLAGS="-m32"
  cmake -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}" \
        -DLIBUNWIND_ENABLE_SHARED=ON \
        -DLIBUNWIND_ENABLE_STATIC=ON \
        -DCMAKE_EXE_LINKER_FLAGS="-m32" \
        -DCMAKE_SHARED_LINKER_FLAGS="-m32" \
        "${ROOT}"
fi

cmake --build . -- -j$(nproc)
cmake --install . --prefix "${INSTALL_DIR}"

# Collect libs and headers
mkdir -p "${STAGING_DIR}/lib" "${STAGING_DIR}/include"
cp -a "${INSTALL_DIR}/lib"/* "${STAGING_DIR}/lib/" || true
cp -a "${INSTALL_DIR}/include"/* "${STAGING_DIR}/include/"

cd "${ROOT}"
zip -r "libunwind-${ARCH}.zip" "staging-${ARCH}"