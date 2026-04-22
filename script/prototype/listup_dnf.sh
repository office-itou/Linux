#!/bin/bash

set -eu

while read -r P W
do
  read -r p w r < <(  dnf search "${P%%.*}" 2> /dev/null | grep -E "^${P} :")
  printf "    %-36s# %s\n" "${p%%.*}" "$r"
done < <(dnf list --installed)
