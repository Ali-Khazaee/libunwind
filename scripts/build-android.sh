#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 2 ]; then
  echo "Usage: $0 <abi> <ndk_path> [api_level]"
  echo "Example: $0 armeabi-v7a /home/runner/work/libunwind/android-ndk-r25b 21"
  exit 1
fi

ABI="$1"
NDK_PATH="$2"
API_LEVEL="${3:-21}"

ROOT="$(pwd)"
BUILD_DIR="${ROOT}/build-android-${ABI}"
INSTALL_DIR="${ROOT}/install-android-${ABI}"
STAGING_DIR="${ROOT}/staging-android-${ABI}"

mkdir -p "${BUILD_DIR}" "${INSTALL_DIR}" "${STAGING_DIR}"
cd "${BUILD_DIR}"

cmake -DCMAKE_BUILD_TYPE=Release \
      -DLIBUNWIND_ENABLE_SHARED=ON \
      -DLIBUNWIND_ENABLE_STATIC=ON \
      -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}" \
      -DANDROID_NDK="${NDK_PATH}" \
      -DCMAKE_TOOLCHAIN_FILE="${NDK_PATH}/build/cmake/android.toolchain.cmake" \
      -DANDROID_ABI="${ABI}" \
      -DANDROID_NATIVE_API_LEVEL="${API_LEVEL}" \
      "${ROOT}"

cmake --build . -- -j$(nproc)
cmake --install . --prefix "${INSTALL_DIR}"

# Collect libs and headers
mkdir -p "${STAGING_DIR}/lib" "${STAGING_DIR}/include"
cp -a "${INSTALL_DIR}/lib"/* "${STAGING_DIR}/lib/" || true
cp -a "${INSTALL_DIR}/include"/* "${STAGING_DIR}/include/"

cd "${ROOT}"
zip -r "libunwind-android-${ABI}.zip" "staging-android-${ABI}"