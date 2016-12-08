#!/bin/sh

canonicalpath() {
  if [ -d $1 ]; then
    pushd $1 > /dev/null 2>&1
    echo $PWD
  elif [ -f $1 ]; then
    pushd $(dirname $1) > /dev/null 2>&1
    echo $PWD/$(basename $1)
  else
    echo "Invalid path $1"
  fi
  popd > /dev/null 2>&1
}

# u=rwx,g=rwx,o=rx
umask 0002

# find locations relative to this script
SCRIPT_LOC=$(canonicalpath $0)
BIN_DIR=$(dirname ${SCRIPT_LOC})
PIPE_DIR=$(dirname ${BIN_DIR})

# use today if date not passed to script
if [[ $# -lt 1 ]]; then
  DATE=$(date +"%Y%m%d")
else
  DATE=$1
fi

MACHINE=$(hostname | sed -e 's/\..*$//')
if [[ $# -lt 2 ]]; then
  CONFIG=${PIPE_DIR}/config/kcor.${USER}.${MACHINE}.production.cfg
else
  CONFIG=${PIPE_DIR}/config/kcor.${USER}.${MACHINE}.${2}.cfg
fi

if [ "$(uname)" == "Darwin" ]; then
  IDL=/Applications/exelis/idl/bin/idl
else
  IDL=/opt/share/exelis/idl82/bin/idl
fi

# setup IDL paths
SSW_DIR=${PIPE_DIR}/ssw
GEN_DIR=${PIPE_DIR}/gen
LIB_DIR=${PIPE_DIR}/lib
KCOR_SRC_DIR=${PIPE_DIR}/src
KCOR_PATH=+${KCOR_SRC_DIR}:${SSW_DIR}:${GEN_DIR}:+${LIB_DIR}:"<IDL_DEFAULT>"
KCOR_DLM_PATH=${KCOR_SRC_DIR}/realtime:${LIB_DIR}/mysql:"<IDL_DEFAULT>"

${IDL} -IDL_STARTUP "" -IDL_PATH ${KCOR_PATH} -IDL_DLM_PATH ${KCOR_DLM_PATH} -e "kcor_eod, '${DATE}', config_filename='${CONFIG}'"
