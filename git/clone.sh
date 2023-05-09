#!/bin/bash

while read line
do
  git clone $line

done < targets.txt