#!/bin/sh

if [ $# -ne 2 ]; then
  echo "Usage: $0 [tagFilter] [outputDirectory]"
  echo
  echo "  [tagFilter] will be passed to "git tag --list" to filter the tags to be built."
  echo "  [outputDirectory] will contain log files and the resulting soljson.js builds."
  exit 1
fi

TAGS="$1"
OUTPUTDIR="$2"
SCRIPTDIR="$(realpath $(dirname $0))"

if [ ! -d "${OUTPUTDIR}" ]; then
  echo "Output directory ${OUTPUTDIR} does not exist!."
  exit 1
fi
OUTPUTDIR=$(realpath "${OUTPUTDIR}")

docker run --rm -v "${OUTPUTDIR}":/tmp/output -v "${SCRIPTDIR}":/tmp/scripts:ro -it trzeci/emscripten:sdk-tag-1.39.3-64bit /tmp/scripts/docker-scripts/rebuild_tags.sh "${TAGS}" /tmp/output
