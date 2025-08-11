#!/bin/bash

set -eu

# shellcheck disable=SC2034
git ls-tree -r HEAD | while read -r mode type sha1 file; do
  if [[ "${type}" = "blob" ]]; then
    file="$(printf "%s" "${file}")"
    file="${file#\"}"
    file="${file%\"}"
    date="$(git log -1 --format="%ai" "${file}")"
    if [[ -n "${date}" ]]; then
      date="${date:0:-2}:${date:$(("${#date}"-2)):2}"
      touch -d "${date}" "${file}"
    fi
  fi
done
