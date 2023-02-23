#!/bin/zsh
helm search repo cloudzcp | tail -n +2 | awk '{printf "%s,%s,%s\n",$1, $2, $3}'
