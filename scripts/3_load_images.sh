#!/bin/bash

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
# shellcheck source=./util.sh
source "${BASE_DIR}/utils.sh"
IMAGE_DIR=images

cd "${BASE_DIR}" || return

function load_image_files() {
  images=$(get_images)
  for image in ${images}; do
    echo ""
    filename=$(basename "${image}").tar
    filename_windows=${filename/:/_}
    if [[ -f ${IMAGE_DIR}/${filename_windows} ]]; then
      filename=${filename_windows}
    fi
    if [[ ! -f ${IMAGE_DIR}/${filename} ]]; then
      if [[ ! ${filename} =~ xpack* && ! ${filename} =~ omnidb* ]]; then
        echo_red "$(gettext -s 'Image file not found'): ${IMAGE_DIR}/${filename}"
      fi
      continue
    fi

    echo -n "${image} <= ${IMAGE_DIR}/${filename} "
    md5_filename=$(basename "${image}").md5
    md5_path=${IMAGE_DIR}/${md5_filename}
    image_id=$(docker inspect -f "{{.ID}}" "${image}" 2>/dev/null || echo "")
    saved_id=""

    if [[ -f "${md5_path}" ]]; then
      saved_id=$(cat "${md5_path}")
    fi
    if [[ ${image_id} != "${saved_id}" ]]; then
      echo
      docker load <"${IMAGE_DIR}/${filename}"
    else
      echo "$(gettext -s 'Mirror loaded, skipping')"
    fi
  done
}

function pull_image() {
  images=$(get_images public)
  for image in ${images}; do
    if [[ ! "$(docker images | grep $(echo ${image%:*}) | grep $(echo ${image#*:}) )" ]]; then
      docker pull "${image}"
      echo ""
    fi
  done
}

function main() {
  if [[ -d "${IMAGE_DIR}" && -f "${IMAGE_DIR}/redis:6-alpine.tar" ]]; then
    load_image_files
  else
    pull_image
  fi
}

if [[ "$0" == "${BASH_SOURCE[0]}" ]]; then
  main
fi
