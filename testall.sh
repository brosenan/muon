#!/bin/bash

for file in lib/*-test.mu
do
    basename=$(basename $file)
    ./muon -T ${basename%.*}
done
