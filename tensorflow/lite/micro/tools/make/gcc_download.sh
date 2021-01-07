#!/bin/bash
# Copyright 2021 The TensorFlow Authors. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ==============================================================================
#
# Called with following arguments:
# 1 - Path to the downloads folder which is typically
#     tensorflow/lite/micro/tools/make/downloads
#
# This script is called from the Makefile and uses the following convention to
# enable determination of sucess/failure:
#
#   - If the script is successful, the only output on stdout should be SUCCESS.
#     The makefile checks for this particular string.
#
#   - Any string on stdout that is not SUCCESS will be shown in the makefile as
#     the cause for the script to have failed.
#
#   - Any other informational prints should be on stderr.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR=${SCRIPT_DIR}/../../../../..
cd "${ROOT_DIR}"

source tensorflow/lite/micro/tools/make/bash_helpers.sh

DOWNLOADS_DIR=${1}
if [ ! -d ${DOWNLOADS_DIR} ]; then
  echo "The top-level downloads directory: ${DOWNLOADS_DIR} does not exist."
  exit 1
fi

DOWNLOADED_GCC_PATH=${DOWNLOADS_DIR}/gcc_embedded

if [ -d ${DOWNLOADED_GCC_PATH} ]; then
  echo >&2 "${DOWNLOADED_GCC_PATH} already exists, skipping the download."
else

  if [[ ${OSTYPE} == "linux" ]]; then
    GCC_URL="https://developer.arm.com/-/media/Files/downloads/gnu-rm/10-2020q4/gcc-arm-none-eabi-10-2020-q4-major-x86_64-linux.tar.bz2"
    EXPECTED_MD5="8312c4c91799885f222f663fc81f9a31"
  elif [[ ${HOST_OS} == "darwin" ]]; then
    GCC_URL="https://developer.arm.com/-/media/Files/downloads/gnu-rm/10-2020q4/gcc-arm-none-eabi-10-2020-q4-major-mac.tar.bz2"
    EXPECTED_MD5="bc8ae26d7c429f30d583a605a4bcf9bc"
  else
    GCC_URL="https://developer.arm.com/-/media/Files/downloads/gnu-rm/10-2020q4/gcc-arm-none-eabi-10-2020-q4-major-win32.zip"
    EXPECTED_MD5="a66be9828cf3c57d7d21178e07cd8904"
  fi

  FILE_EXTENSION="${GCC_URL##*.}"
  TEMPFILE=$(mktemp -d)/temp_file

  wget ${GCC_URL} -O ${TEMPFILE} >&2
  check_md5 ${TEMPFILE} ${EXPECTED_MD5}

  mkdir "${DOWNLOADED_GCC_PATH}"
  if [[ ${FILE_EXTENSION} == "bz2" ]]; then
    tar -C "${DOWNLOADED_GCC_PATH}" --strip-components=1 -xjf ${TEMPFILE}
  elif [[ ${FILE_EXTENSION} == "zip" ]]; then
    TEMPDIR=$(mktemp -d)
    unzip ${TEMPFILE} -d ${TEMPDIR} 2>&1 1>/dev/null
    # If the zip file contains nested directories, extract the files from the
    # inner directory.
    if [ $(find $TEMPDIR/* -maxdepth 0 | wc -l) = 1 ] && [ -d $TEMPDIR/* ]; then
      # unzip has no strip components, so unzip to a temp dir, and move the
      # files we want from the tempdir to destination.
      cp -R ${TEMPDIR}/*/* ${dir}/
    else
      cp -R ${TEMPDIR}/* ${dir}/
    fi
  else
    echo "Error unsupported archive type. Failed to extract tool after download."
    exit 1
  fi
fi

echo "SUCCESS"
