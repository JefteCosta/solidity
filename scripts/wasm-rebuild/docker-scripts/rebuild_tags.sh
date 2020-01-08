#!/bin/bash -e

# This script is expected to be run inside the docker image trzeci/emscripten:sdk-tag-1.39.3-64bit.
# Its main purpose is to be used by ../rebuild.sh.

# Usage: $0 [tagFilter] [outputDirectory]

# The output directory must be outside the repository,
# since the script will prune the repository directory after
# each build.

TAGS="$1"
OUTPUTDIR="$2"
SCRIPTDIR="$(realpath $(dirname $0))"
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

echo "Check out solidity repository..."
if [ -d /root/project ]; then
	echo "Solidity repo checkout already exists."
else
	git clone https://github.com/ethereum/solidity /root/project --quiet
fi

echo "Check out solc-js repository..."
if [ -d /root/solc-js ]; then
	echo "solc-js repo checkout already exists."
else
	git clone https://github.com/ethereum/solc-js /root/solc-js --quiet
fi

echo "Create symbolic links for backwards compatibility with older emscripten docker images."
# Backwards compatibility with older emscripten docker images.
cd /tmp
ln -sf /emsdk_portable/node/current/* /emsdk_portable/node/
ln -sf /emsdk_portable/emscripten/sdk/ /emsdk_portable/
ln -sf sdk /emsdk_portable/emscripten/bin
ln -sf /emsdk_portable/emscripten/bin/* /usr/local/bin
rm -rf /src
ln -sf /root/project /src

apt-get -qq update > /dev/null 2>&1
apt-get -qq install cmake > /dev/null 2>&1

echo "Create output directories."
mkdir -p "${OUTPUTDIR}"
mkdir -p "${OUTPUTDIR}"/log
mkdir -p "${OUTPUTDIR}"/success
mkdir -p "${OUTPUTDIR}"/fail
mkdir -p "${OUTPUTDIR}"/test
mkdir -p "${OUTPUTDIR}"/bin

echo "Prepare solc-js."
cd /root/solc-js
npm install > /dev/null 2>&1


for TAG in $(git tag --list ${TAGS} | tac); do

cd /src

git submodule deinit --all -q
git reset --hard HEAD --quiet
git clean -f -d -x --quiet
git checkout $TAG --quiet
git submodule init -q
git submodule update -q
ln -s $(pwd) solidity

if [ -f ./scripts/get_version.sh ]; then
VERSION=$(./scripts/get_version.sh)
else
VERSION=$(echo $TAG | cut -d v -f 2)
fi

if [ ! -f "${OUTPUTDIR}/bin/soljson-${TAG}.js" ]; then

echo -ne "BUILDING ${CYAN}${TAG}${RESET}... "

rm -f "${OUTPUTDIR}"/success/build-$TAG.txt
rm -f "${OUTPUTDIR}"/fail/build-$TAG.txt

set +e
"${SCRIPTDIR}"/rebuild_current.sh > "${OUTPUTDIR}"/log/build-$TAG.txt 2>&1
EXIT_STATUS=$?

if [ -f upload/soljson.js ]; then
	cp upload/soljson.js "${OUTPUTDIR}"/bin/soljson-${TAG}.js
elif [ -f build/solc/soljson.js ]; then
	cp build/solc/soljson.js "${OUTPUTDIR}"/bin/soljson-${TAG}.js
elif [ -f emscripten_build/solc/soljson.js ]; then
	cp emscripten_build/solc/soljson.js "${OUTPUTDIR}"/bin/soljson-${TAG}.js
else
	EXIT_STATUS=1
fi


if [ $EXIT_STATUS -eq 0 ]; then
  echo -e "${GREEN}SUCCESS${RESET}"
  ln -s ../log/build-$TAG.txt "${OUTPUTDIR}"/success
elif [ -f "${OUTPUTDIR}"/bin/soljson-${TAG}.js ]; then
  echo -e "${ORANGE}SUCCESS (but some error code)${RESET}"
  ln -s ../log/build-$TAG.txt "${OUTPUTDIR}"/success
else
  echo -e "${RED}FAIL${RESET}"
  ln -s ../log/build-$TAG.txt "${OUTPUTDIR}"/fail
fi
set -e

fi

if [ -f "${OUTPUTDIR}/bin/soljson-${TAG}.js" ]; then

echo -ne "TESTING ${CYAN}${TAG}${RESET}... "

rm -f "${OUTPUTDIR}"/success/test-$TAG.txt
rm -f "${OUTPUTDIR}"/fail/test-$TAG.txt

cd /root/solc-js

npm version --allow-same-version --no-git-tag-version ${VERSION} > /dev/null

ln -sf "${OUTPUTDIR}"/bin/soljson-${TAG}.js soljson.js

set +e
npm test > "${OUTPUTDIR}"/log/test-$TAG.txt 2>&1

if [ $? -eq 0 ]; then
  echo -e "${GREEN}SUCCESS${RESET}"
  ln -s ../log/test-$TAG.txt "${OUTPUTDIR}"/success
else
  echo -e "${RED}FAIL${RESET}"
  ln -s ../log/test-$TAG.txt "${OUTPUTDIR}"/fail
fi
set -e

fi

done
